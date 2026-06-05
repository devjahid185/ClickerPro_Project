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

  Stream<BookingRow?> watchById(String id) {
    return (select(
      bookingsTable,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
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
      q.where((t) => t.title.like('%$search%'));
    }
    return q;
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
    switch (sort) {
      case BookingsListSort.dateDesc:
        q.orderBy([(t) => OrderingTerm.desc(t.date)]);
        break;
      case BookingsListSort.dateAsc:
        q.orderBy([(t) => OrderingTerm.asc(t.date)]);
        break;
      case BookingsListSort.createdAtDesc:
        q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
        break;
    }
  }
}
