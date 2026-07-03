// lib/core/db/daos/bookings_dao.dart
//
// DAO for Bookings (Events). Owns the role-scoped list / month queries that
// the BookingRepository builds on. Sort, paging, status / type / date / client
// filtering, and search-by-title are all expressed as Drift expressions so the
// stream can be watched directly without post-filtering in Dart.
//
// The DAO accepts primitives (UserRole, studioId, currentUserId) instead of a
// RolePolicy reference to keep this layer free of dependencies on
// `core/role/`. The repository layer marshals the policy into these
// primitives.

import 'package:drift/drift.dart';

import '../../../features/auth/domain/user_role.dart';
import '../app_database.dart';
import '../tables/assignments_table.dart';
import '../tables/bookings_table.dart';

part 'bookings_dao.g.dart';

/// Sort directions accepted by [BookingsDao.watchList]. The repository maps
/// its `BookingSort` enum onto this DAO-local enum.
enum BookingsListSort {
  dateDesc,
  dateAsc,
  createdAtDesc,
  // clientNameAsc is intentionally omitted from the DAO; sorting by joined
  // client.name is performed at the repository layer after watching, since
  // Drift `watch` does not compose easily with cross-table ORDER BY here.
}

/// Simple query parameter struct accepted by [BookingsDao.watchList] and
/// [BookingsDao.watchMonth]. Kept local to this file so the DAO does not
/// import `features/bookings/domain/booking_filter.dart`. The repository layer
/// adapts its higher-level `BookingFilter` value object into this struct.
class BookingsListQuery {
  final DateTime? from;
  final DateTime? to;
  final Set<String> statuses; // BookingStatus.name values
  final Set<String> types; // EventType.name values
  final String? clientId;
  final String? search; // matches BookingsTable.title with LIKE %search%
  final BookingsListSort sort;
  final int page;
  final int pageSize;

  const BookingsListQuery({
    this.from,
    this.to,
    this.statuses = const {},
    this.types = const {},
    this.clientId,
    this.search,
    this.sort = BookingsListSort.dateDesc,
    this.page = 0,
    this.pageSize = 20,
  });
}

@DriftAccessor(tables: [BookingsTable, AssignmentsTable])
class BookingsDao extends DatabaseAccessor<AppDatabase>
    with _$BookingsDaoMixin {
  BookingsDao(super.db);

  // ───────────────────────── Watches ─────────────────────────

  Stream<List<BookingRow>> watchList(
    BookingsListQuery query, {
    required UserRole role,
    required String studioId,
    required String currentUserId,
  }) {
    final select = _baseSelect(query);
    _applyRoleScope(
      select,
      role: role,
      studioId: studioId,
      currentUserId: currentUserId,
    );
    _applyOrdering(select, query.sort);
    select.limit(query.pageSize * (query.page + 1), offset: 0);
    return select.watch();
  }

  /// Unlimited variant of [watchList] — every row matching the filter +
  /// role scope, no page window. Used by aggregate consumers (dashboard
  /// metrics, finance, due totals, the double-booking conflict guard) that
  /// must see the studio's ENTIRE booking set, not just the first page the
  /// list screen has scrolled to. Reusing the paginated stream there used
  /// to silently cap every one of those calculations at 20 bookings.
  Stream<List<BookingRow>> watchAllForRole(
    BookingsListQuery query, {
    required UserRole role,
    required String studioId,
    required String currentUserId,
  }) {
    final select = _baseSelect(query);
    _applyRoleScope(
      select,
      role: role,
      studioId: studioId,
      currentUserId: currentUserId,
    );
    _applyOrdering(select, query.sort);
    return select.watch();
  }

  Stream<BookingRow?> watchById(String id) {
    return (select(
      bookingsTable,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Looks up the local row a server row corresponds to. Used by the
  /// remote-refresh merge so a pulled server row updates the existing
  /// local row instead of inserting a duplicate under the server id.
  Future<BookingRow?> getByRemoteId(String remoteId) {
    return (select(bookingsTable)
          ..where((t) => t.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<List<BookingRow>> watchMonth(
    int year,
    int month, {
    required UserRole role,
    required String studioId,
    required String currentUserId,
  }) {
    final monthStart = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1, 1);
    final monthQuery = BookingsListQuery(
      from: monthStart,
      to: nextMonth,
      sort: BookingsListSort.dateAsc,
      pageSize: 1000, // calendars need the whole month
    );
    final select = _baseSelect(monthQuery);
    _applyRoleScope(
      select,
      role: role,
      studioId: studioId,
      currentUserId: currentUserId,
    );
    _applyOrdering(select, monthQuery.sort);
    return select.watch();
  }

  // ───────────────────────── Mutations ─────────────────────────

  Future<void> upsert(BookingsTableCompanion row) async {
    await into(bookingsTable).insertOnConflictUpdate(row);
  }

  Future<void> markPending(String id, {bool pending = true}) async {
    await (update(bookingsTable)..where((t) => t.id.equals(id))).write(
      BookingsTableCompanion(
        pending: Value(pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// After an Outbox drain succeeds, stamp the local row with the server's
  /// `remoteId` and `updatedAt`, and clear the pending flag.
  Future<void> markSynced(
    String id, {
    required String remoteId,
    required DateTime updatedAt,
  }) async {
    await (update(bookingsTable)..where((t) => t.id.equals(id))).write(
      BookingsTableCompanion(
        remoteId: Value(remoteId),
        updatedAt: Value(updatedAt),
        pending: const Value(false),
      ),
    );
  }

  Future<void> deleteById(String id) async {
    await (delete(bookingsTable)..where((t) => t.id.equals(id))).go();
  }

  // ───────────────────────── Internal helpers ─────────────────────────

  SimpleSelectStatement<$BookingsTableTable, BookingRow> _baseSelect(
    BookingsListQuery query,
  ) {
    final q = select(bookingsTable);
    if (query.from != null) {
      q.where((t) => t.date.isBiggerOrEqualValue(query.from!));
    }
    if (query.to != null) {
      q.where((t) => t.date.isSmallerThanValue(query.to!));
    }
    if (query.statuses.isNotEmpty) {
      q.where((t) => t.status.isIn(query.statuses.toList()));
    }
    if (query.types.isNotEmpty) {
      q.where((t) => t.eventType.isIn(query.types.toList()));
    }
    if (query.clientId != null) {
      q.where((t) => t.clientId.equals(query.clientId!));
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      // Photographers search by who/where/when, not the internal booking
      // title. Match title, client name/phone, venue and the bride/groom
      // names so a name or number actually finds the event. LIKE is
      // case-insensitive for ASCII in SQLite; the leading/trailing % make it
      // a "contains" match. A query that reads as a date (5/7/2026,
      // 2026-07-05, 5-7-2026) additionally matches that calendar day.
      final like = '%$search%';
      final searchDay = _parseSearchDate(search);
      q.where((t) {
        var expr =
            t.title.like(like) |
            t.clientName.like(like) |
            t.clientPhone.like(like) |
            t.venue.like(like) |
            t.brideName.like(like) |
            t.groomName.like(like);
        if (searchDay != null) {
          final next = searchDay.add(const Duration(days: 1));
          expr = expr |
              (t.date.isBiggerOrEqualValue(searchDay) &
                  t.date.isSmallerThanValue(next));
        }
        return expr;
      });
    }
    return q;
  }

  /// Reads a search string as a calendar date. Accepts the Bangladeshi
  /// day-first forms `d/m/yyyy` and `d-m-yyyy` (also `d/m` = current year)
  /// plus ISO `yyyy-mm-dd`. Returns local midnight, or null when the text
  /// isn't a date.
  static DateTime? _parseSearchDate(String raw) {
    final s = raw.trim();
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s);
    if (iso != null) {
      return _validDay(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    final dmy = RegExp(r'^(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?$')
        .firstMatch(s);
    if (dmy != null) {
      final yearRaw = dmy.group(3);
      var year = yearRaw == null ? DateTime.now().year : int.parse(yearRaw);
      if (year < 100) year += 2000;
      return _validDay(year, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    return null;
  }

  static DateTime? _validDay(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    // Reject rollovers like 31/2 → 2/3.
    return (date.month == m && date.day == d) ? date : null;
  }

  void _applyRoleScope(
    SimpleSelectStatement<$BookingsTableTable, BookingRow> q, {
    required UserRole role,
    required String studioId,
    required String currentUserId,
  }) {
    // Subquery selecting bookingIds where the current user has an assignment.
    final assignedSub = selectOnly(assignmentsTable)
      ..addColumns([assignmentsTable.bookingId])
      ..where(assignmentsTable.userId.equals(currentUserId));

    switch (role) {
      case UserRole.webAdmin:
      case UserRole.owner:
      case UserRole.both:
        // All bookings in the studio.
        q.where((t) => t.studioId.equals(studioId));
        break;
      case UserRole.manager:
        // Studio match AND (createdBy == userId OR EXISTS assignment).
        q.where(
          (t) =>
              t.studioId.equals(studioId) &
              (t.createdByUserId.equals(currentUserId) |
                  t.id.isInQuery(assignedSub)),
        );
        break;
      case UserRole.freelancer:
        // createdBy == userId OR EXISTS assignment.
        q.where(
          (t) =>
              t.createdByUserId.equals(currentUserId) |
              t.id.isInQuery(assignedSub),
        );
        break;
    }
  }

  void _applyOrdering(
    SimpleSelectStatement<$BookingsTableTable, BookingRow> q,
    BookingsListSort sort,
  ) {
    // startTime is the tiebreak within a day — without it same-day bookings
    // fall back to rowid (creation) order, which read as "not date-wise".
    switch (sort) {
      case BookingsListSort.dateDesc:
        q.orderBy([
          (t) => OrderingTerm.desc(t.date),
          (t) => OrderingTerm.asc(t.startTime),
        ]);
        break;
      case BookingsListSort.dateAsc:
        q.orderBy([
          (t) => OrderingTerm.asc(t.date),
          (t) => OrderingTerm.asc(t.startTime),
        ]);
        break;
      case BookingsListSort.createdAtDesc:
        q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
        break;
    }
  }
}
