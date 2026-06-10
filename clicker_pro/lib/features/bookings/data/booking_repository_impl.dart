// lib/features/bookings/data/booking_repository_impl.dart
//
// Local-first booking repository. Mirrors the Foundation MVP
// `UserRepositoryImpl` pattern: Drift writes commit BEFORE the network
// call, network failures fall through to an `OutboxItem` enqueue, and the
// caller always sees the locally-saved version so the UI keeps moving.
//
// Capability gates are checked up-front before any side effect.
// `RolePolicyDeniedException` is thrown for callers without the required
// `Capability` so the UI can surface a friendly message.
//
// See `.kiro/specs/bookings-module/design.md` → "Components and
// Interfaces" + "Outbox Worker Extensions" for entityType strings and
// drain semantics.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/booking_status/booking_status.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/assignments_dao.dart';
import '../../../core/db/daos/bookings_dao.dart';
import '../../../core/db/daos/clients_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/packages_dao.dart';
import '../../../core/db/daos/payments_dao.dart';
import '../../../core/db/daos/re_edit_requests_dao.dart';
import '../../../core/db/daos/status_history_dao.dart';
import '../../../core/db/daos/task_progress_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../../auth/domain/user_role.dart';
import '../domain/assignment.dart';
import '../domain/assignment_role.dart';
import '../domain/booking.dart';
import '../domain/booking_detail_envelope.dart';
import '../domain/booking_filter.dart';
import '../domain/booking_repository.dart';
import '../domain/booking_sort.dart';
import '../domain/client.dart';
import '../domain/event_type.dart';
import '../domain/package.dart';
import '../domain/payment.dart';
import '../domain/payment_kind.dart';
import '../domain/re_edit_request.dart';
import '../domain/re_edit_status.dart';
import '../domain/shift.dart';
import '../domain/status_history_entry.dart';
import '../domain/task_progress.dart';
import 'booking_api.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({required BookingApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final BookingApi _api;
  final AppDatabase _db;

  BookingsDao get _bookings => _db.bookingsDao;
  ClientsDao get _clients => _db.clientsDao;
  AssignmentsDao get _assignments => _db.assignmentsDao;
  PaymentsDao get _payments => _db.paymentsDao;
  PackagesDao get _packages => _db.packagesDao;
  StatusHistoryDao get _history => _db.statusHistoryDao;
  ReEditRequestsDao get _reEdits => _db.reEditRequestsDao;
  TaskProgressDao get _taskProgress => _db.taskProgressDao;
  OutboxDao get _outbox => _db.outboxDao;
  UsersDao get _users => _db.usersDao;

  // ───────────────────────── Reads ─────────────────────────

  @override
  Stream<List<Booking>> watchList(
    BookingFilter filter, {
    required RolePolicy policy,
    required String currentUserId,
    required int page,
    int pageSize = 20,
  }) async* {
    final studioId = await _resolveStudioId(policy.role, currentUserId);
    final query = _filterToQuery(filter, page: page, pageSize: pageSize);
    yield* _bookings
        .watchList(
          query,
          role: policy.role,
          studioId: studioId,
          currentUserId: currentUserId,
        )
        .map((rows) => rows.map(_rowToBooking).toList(growable: false));
  }

  @override
  Stream<Booking?> watch(String localId) {
    return _bookings
        .watchById(localId)
        .map((row) => row == null ? null : _rowToBooking(row));
  }

  @override
  Stream<List<Booking>> watchMonth(
    int year,
    int month, {
    required RolePolicy policy,
    required String currentUserId,
  }) async* {
    final studioId = await _resolveStudioId(policy.role, currentUserId);
    yield* _bookings
        .watchMonth(
          year,
          month,
          role: policy.role,
          studioId: studioId,
          currentUserId: currentUserId,
        )
        .map((rows) => rows.map(_rowToBooking).toList(growable: false));
  }

  @override
  Future<Booking> getById(String localId) async {
    final row = await _bookings.watchById(localId).first;
    if (row == null) {
      throw StateError('Booking not found: $localId');
    }
    return _rowToBooking(row);
  }

  @override
  Future<BookingDetailEnvelope> getDetail(String localId) async {
    final bookingRow = await _bookings.watchById(localId).first;
    if (bookingRow == null) {
      throw StateError('Booking not found: $localId');
    }
    final booking = _rowToBooking(bookingRow);

    Client? client;
    if (booking.clientId != null) {
      final cRow = await _clients.watchById(booking.clientId!).first;
      if (cRow != null) client = _rowToClient(cRow);
    }

    Package? pkg;
    if (booking.packageId != null) {
      // PackagesDao does not expose `watchById`; pull from `watchAll` and
      // filter. Package lists are short (a studio rarely defines >50)
      // so the cost is negligible.
      final all = await _packages.watchAll().first;
      final match = all.where((p) => p.id == booking.packageId!);
      if (match.isNotEmpty) pkg = _rowToPackage(match.first);
    }

    final assignments = await _assignments.watchByBooking(localId).first;
    final payments = await _payments.watchByBooking(localId).first;
    final history = await _history.watchByBooking(localId).first;
    final reEdits = await _reEdits.watchByBooking(localId).first;
    final taskProgress = await _taskProgress.watchByBooking(localId).first;

    return BookingDetailEnvelope(
      booking: booking,
      client: client,
      assignments: assignments.map(_rowToAssignment).toList(growable: false),
      payments: payments.map(_rowToPayment).toList(growable: false),
      package: pkg,
      statusHistory: history.map(_rowToStatusHistory).toList(growable: false),
      reEditRequests: reEdits.map(_rowToReEditRequest).toList(growable: false),
      taskProgress: taskProgress
          .map(_rowToTaskProgress)
          .toList(growable: false),
    );
  }

  @override
  Future<List<Booking>> fetchPage(
    BookingFilter filter, {
    required int page,
    int pageSize = 20,
  }) async {
    final result = await _api.list(filter, page: page, pageSize: pageSize);
    return result.items;
  }

  @override
  Future<void> refreshFromRemote({
    BookingFilter? filter,
    String? singleEventId,
  }) async {
    try {
      if (singleEventId != null) {
        final envelope = await _api.get(singleEventId);
        await _upsertEnvelope(envelope);
        return;
      }
      final result = await _api.list(filter ?? const BookingFilter());
      for (final booking in result.items) {
        await _bookings.upsert(
          await _bookingToCompanion(await _mergeWithLocal(booking),
              pending: false),
        );
      }
    } on ApiException catch (e, st) {
      AppLogger.w('booking', 'refreshFromRemote failed: ${e.message}');
      AppLogger.e('booking', e, st);
    }
  }

  /// Same merge for the client carried by a detail envelope: match by
  /// `remoteId`, keep the local id and local-only fields.
  Future<Client?> _mergeEnvelopeClient(Client? incoming) async {
    if (incoming == null) return null;
    final remoteId = incoming.remoteId;
    if (remoteId == null) return incoming;
    final existingRow = await _clients.getByRemoteId(remoteId);
    if (existingRow == null) return incoming;
    if (existingRow.pending) return _rowToClient(existingRow);
    final local = _rowToClient(existingRow);
    return local.copyWith(
      remoteId: remoteId,
      name: incoming.name,
      phone: incoming.phone.isNotEmpty ? incoming.phone : local.phone,
      email: incoming.email ?? local.email,
      updatedAt: incoming.updatedAt,
      pending: false,
    );
  }

  /// Reconciles a pulled server booking with its local counterpart (matched
  /// by `remoteId`). The local row keeps its id and every field the Laravel
  /// schema does not persist (times, bride/groom, package economics, …);
  /// the server-authoritative fields are adopted. Rows with no local match
  /// (created on another device / the web app) pass through unchanged.
  Future<Booking> _mergeWithLocal(Booking incoming) async {
    final remoteId = incoming.remoteId;
    if (remoteId == null) return incoming;
    final existingRow = await _bookings.getByRemoteId(remoteId);
    if (existingRow == null) return incoming;
    if (existingRow.pending) {
      // Local unsynced edits win until the outbox drains them.
      return _rowToBooking(existingRow);
    }
    final local = _rowToBooking(existingRow);
    return local.copyWith(
      remoteId: remoteId,
      title: incoming.title,
      eventType: incoming.eventType,
      date: incoming.date,
      shift: incoming.shift,
      venue: incoming.venue ?? local.venue,
      status: incoming.status,
      customPrice: incoming.customPrice ?? local.customPrice,
      notes: incoming.notes ?? local.notes,
      clientName: incoming.clientName ?? local.clientName,
      clientPhone: incoming.clientPhone ?? local.clientPhone,
      updatedAt: incoming.updatedAt,
      pending: false,
    );
  }

  // ───────────────────────── Writes ─────────────────────────

  @override
  Future<Booking> save(Booking booking, {required RolePolicy policy}) async {
    final required = booking.remoteId == null
        ? Capability.createBooking
        : Capability.editBooking;
    if (!policy.can(required)) {
      throw RolePolicyDeniedException(capability: required, role: policy.role);
    }

    final stamped = booking.copyWith(updatedAt: DateTime.now(), pending: true);
    await _bookings.upsert(await _bookingToCompanion(stamped, pending: true));

    final isCreate = booking.remoteId == null;
    try {
      final remote = isCreate
          ? await _api.create(stamped)
          : await _api.patch(booking.remoteId!, stamped.toJson());
      final synced = remote.copyWith(pending: false);
      await _bookings.upsert(await _bookingToCompanion(synced, pending: false));
      return synced;
    } catch (e, st) {
      AppLogger.w('booking', 'save remote failed; queued in outbox: $e');
      AppLogger.e('booking', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'booking',
          entityId: stamped.id,
          op: isCreate ? 'create' : 'update',
          payloadJson: jsonEncode(stamped.toJson()),
        ),
      );
      return stamped;
    }
  }

  @override
  Future<void> delete(String localId, {required RolePolicy policy}) async {
    if (!policy.can(Capability.deleteBooking)) {
      throw RolePolicyDeniedException(
        capability: Capability.deleteBooking,
        role: policy.role,
      );
    }

    final row = await _bookings.watchById(localId).first;
    if (row == null) return;

    // Mark pending so the UI shows the row as in-flight while we attempt
    // the network call. If the API succeeds we hard-delete locally; if it
    // fails we leave the pending row + enqueue an outbox delete so the
    // worker can finish the job once connectivity returns.
    await _bookings.markPending(localId, pending: true);

    try {
      if (row.remoteId != null) {
        await _api.delete(row.remoteId!);
      }
      await _bookings.deleteById(localId);
    } catch (e, st) {
      AppLogger.w('booking', 'delete remote failed; queued in outbox: $e');
      AppLogger.e('booking', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'booking',
          entityId: localId,
          op: 'delete',
          payloadJson: jsonEncode({
            'id': localId,
            if (row.remoteId != null) 'remoteId': row.remoteId,
          }),
        ),
      );
    }
  }

  // ───────────────────────── Internal helpers ─────────────────────────

  /// Resolves the studio-scope id for the role-scoped Drift query.
  ///
  /// Owner/Both: their own user id is the studio id (they ARE the studio).
  /// Manager/Freelancer: derive from `users.ownerId` if available, falling
  /// back to `currentUserId` so the query still returns sane results when
  /// the user row hasn't been refreshed yet.
  Future<String> _resolveStudioId(UserRole role, String currentUserId) async {
    if (role == UserRole.owner || role == UserRole.both) {
      return currentUserId;
    }
    final user = await _users.getCurrent();
    return user?.ownerId ?? currentUserId;
  }

  BookingsListQuery _filterToQuery(
    BookingFilter filter, {
    required int page,
    required int pageSize,
  }) {
    return BookingsListQuery(
      from: filter.from,
      to: filter.to,
      statuses: filter.statuses.map((s) => s.name).toSet(),
      types: filter.types.map((t) => t.name).toSet(),
      clientId: filter.clientId,
      search: filter.search,
      sort: _sortToDaoSort(filter.sort),
      page: page,
      pageSize: pageSize,
    );
  }

  BookingsListSort _sortToDaoSort(BookingSort sort) {
    switch (sort) {
      case BookingSort.dateDesc:
        return BookingsListSort.dateDesc;
      case BookingSort.dateAsc:
        return BookingsListSort.dateAsc;
      case BookingSort.createdAtDesc:
        return BookingsListSort.createdAtDesc;
      case BookingSort.clientNameAsc:
        // The DAO does not natively support cross-table client-name
        // ordering; return the closest match and let the UI re-sort if
        // needed. See booking_repository.dart spec § "Sort handling".
        return BookingsListSort.dateDesc;
    }
  }

  /// Upserts every row carried by a `GET /api/bookings/:id` envelope into
  /// Drift. Status history rows are inserted with `insertOnConflictUpdate`
  /// (idempotent on `id`) since the table is append-only and rows are
  /// dedupe-keyed by their id.
  Future<void> _upsertEnvelope(BookingDetailEnvelope envelope) async {
    // Merge against the local row (matched by remoteId) so a detail pull
    // updates in place instead of duplicating under the server id, and so
    // child rows below hang off the correct LOCAL booking id.
    final booking = await _mergeWithLocal(envelope.booking);
    await _bookings.upsert(await _bookingToCompanion(booking, pending: false));
    final client = await _mergeEnvelopeClient(envelope.client);
    if (client != null) {
      await _clients.upsert(_clientToCompanion(client, pending: false));
    }
    final pkg = envelope.package;
    if (pkg != null) {
      await _packages.upsert(_packageToCompanion(pkg, pending: false));
    }
    for (final a in envelope.assignments) {
      await _assignments.upsert(_assignmentToCompanion(a, pending: false));
    }
    for (final p in envelope.payments) {
      await _payments.upsert(_paymentToCompanion(p, pending: false));
    }
    for (final h in envelope.statusHistory) {
      // Re-point at the merged LOCAL booking id (the wire entry carries
      // the server-side id when the booking originated on this device).
      await _history.append(
        _statusHistoryToCompanion(
          h.copyWith(bookingId: booking.id),
          pending: false,
        ),
      );
    }
    for (final r in envelope.reEditRequests) {
      await _reEdits.upsert(_reEditToCompanion(r, pending: false));
    }
    for (final t in envelope.taskProgress) {
      await _taskProgress.upsert(_taskProgressToCompanion(t, pending: false));
    }
  }

  // ── Row → Domain mapping ────────────────────────────────────────────

  Booking _rowToBooking(BookingRow r) => Booking(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    createdByUserId: r.createdByUserId,
    title: r.title,
    eventType: EventType.values.firstWhere(
      (e) => e.name == r.eventType,
      orElse: () => EventType.other,
    ),
    date: r.date,
    startTime: r.startTime,
    endTime: r.endTime,
    shift: Shift.values.firstWhere(
      (s) => s.name == r.shift,
      orElse: () => Shift.day,
    ),
    venue: r.venue,
    outdoor: r.outdoor,
    brideName: r.brideName,
    groomName: r.groomName,
    clientId: r.clientId,
    clientName: r.clientName,
    clientPhone: r.clientPhone,
    packageId: r.packageId,
    customPrice: r.customPrice,
    coverageHours: r.coverageHours,
    extraHourRate: r.extraHourRate,
    driveLink: r.driveLink,
    clientRequirements: _decodeJsonMap(r.clientRequirementsJson),
    notes: r.notes,
    chiefPhotographerUserId: r.chiefPhotographerUserId,
    chiefHours: r.chiefHours,
    hidePaymentFromTeam: r.hidePaymentFromTeam,
    status: BookingStatus.values.firstWhere(
      (s) => s.name == r.status,
      orElse: () => BookingStatus.pending,
    ),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  Client _rowToClient(ClientRow r) => Client(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    name: r.name,
    phone: r.phone,
    email: r.email,
    address: r.address,
    dob: r.dob,
    anniversary: r.anniversary,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  Assignment _rowToAssignment(AssignmentRow r) => Assignment(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    userId: r.userId,
    role: AssignmentRole.values.firstWhere(
      (x) => x.name == r.role,
      orElse: () => AssignmentRole.assistant,
    ),
    payout: r.payout,
    notes: r.notes,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  Payment _rowToPayment(PaymentRow r) => Payment(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    kind: PaymentKind.values.firstWhere(
      (x) => x.name == r.kind,
      orElse: () => PaymentKind.advance,
    ),
    amount: r.amount,
    method: r.method,
    note: r.note,
    paidAt: r.paidAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  Package _rowToPackage(PackageRow r) => Package(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    name: r.name,
    basePrice: r.basePrice,
    coverageHours: r.coverageHours,
    extraHourRate: r.extraHourRate,
    inclusions: _decodeJsonStringList(r.inclusionsJson),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  StatusHistoryEntry _rowToStatusHistory(StatusHistoryEntryRow r) =>
      StatusHistoryEntry(
        id: r.id,
        remoteId: r.remoteId,
        bookingId: r.bookingId,
        fromStatus: BookingStatus.values.firstWhere(
          (s) => s.name == r.fromStatus,
          orElse: () => BookingStatus.pending,
        ),
        toStatus: BookingStatus.values.firstWhere(
          (s) => s.name == r.toStatus,
          orElse: () => BookingStatus.pending,
        ),
        changedByUserId: r.changedByUserId,
        note: r.note,
        at: r.at,
        pending: r.pending,
      );

  ReEditRequest _rowToReEditRequest(ReEditRequestRow r) => ReEditRequest(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    round: r.round,
    editorUserId: r.editorUserId,
    deadline: r.deadline,
    referenceImageUrls: _decodeJsonStringList(r.referenceImageUrlsJson),
    notes: r.notes,
    status: ReEditStatus.values.firstWhere(
      (s) => s.name == r.status,
      orElse: () => ReEditStatus.pending,
    ),
    requestedByUserId: r.requestedByUserId,
    requestedAt: r.requestedAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  TaskProgress _rowToTaskProgress(TaskProgressRow r) => TaskProgress(
    bookingId: r.bookingId,
    userId: r.userId,
    percentage: r.percentage,
    note: r.note,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  // ── Domain → Companion mapping ──────────────────────────────────────

  /// Returns [id] only if it refers to a real row in clients_table; otherwise
  /// null. Guards against dangling/placeholder client ids (e.g. 'pending' or
  /// ids dropped during sync) that would violate the bookings.clientId foreign
  /// key and crash the booking editor. clientName/clientPhone still carry the
  /// human-readable client info, so nulling the id loses nothing the form needs.
  Future<String?> _validClientId(String? id) async {
    if (id == null || id.isEmpty) return null;
    final row = await _clients.watchById(id).first;
    return row == null ? null : id;
  }

  Future<BookingsTableCompanion> _bookingToCompanion(
    Booking b, {
    required bool pending,
  }) async {
    final safeClientId = await _validClientId(b.clientId);
    return BookingsTableCompanion(
      id: Value(b.id),
      remoteId: Value(b.remoteId),
      studioId: Value(b.studioId),
      createdByUserId: Value(b.createdByUserId),
      title: Value(b.title),
      eventType: Value(b.eventType.name),
      date: Value(b.date),
      startTime: Value(b.startTime),
      endTime: Value(b.endTime),
      shift: Value(b.shift.name),
      venue: Value(b.venue),
      outdoor: Value(b.outdoor),
      brideName: Value(b.brideName),
      groomName: Value(b.groomName),
      clientId: Value(safeClientId),
      clientName: Value(b.clientName),
      clientPhone: Value(b.clientPhone),
      packageId: Value(b.packageId),
      customPrice: Value(b.customPrice),
      coverageHours: Value(b.coverageHours),
      extraHourRate: Value(b.extraHourRate),
      driveLink: Value(b.driveLink),
      clientRequirementsJson: Value(_encodeJsonMap(b.clientRequirements)),
      notes: Value(b.notes),
      chiefPhotographerUserId: Value(b.chiefPhotographerUserId),
      chiefHours: Value(b.chiefHours),
      hidePaymentFromTeam: Value(b.hidePaymentFromTeam),
      status: Value(b.status.name),
      createdAt: Value(b.createdAt),
      updatedAt: Value(b.updatedAt),
      pending: Value(pending),
    );
  }

  ClientsTableCompanion _clientToCompanion(Client c, {required bool pending}) {
    return ClientsTableCompanion(
      id: Value(c.id),
      remoteId: Value(c.remoteId),
      studioId: Value(c.studioId),
      name: Value(c.name),
      phone: Value(c.phone),
      email: Value(c.email),
      address: Value(c.address),
      dob: Value(c.dob),
      anniversary: Value(c.anniversary),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
      pending: Value(pending),
    );
  }

  AssignmentsTableCompanion _assignmentToCompanion(
    Assignment a, {
    required bool pending,
  }) {
    return AssignmentsTableCompanion(
      id: Value(a.id),
      remoteId: Value(a.remoteId),
      bookingId: Value(a.bookingId),
      userId: Value(a.userId),
      role: Value(a.role.name),
      payout: Value(a.payout),
      notes: Value(a.notes),
      createdAt: Value(a.createdAt),
      updatedAt: Value(a.updatedAt),
      pending: Value(pending),
    );
  }

  PaymentsTableCompanion _paymentToCompanion(
    Payment p, {
    required bool pending,
  }) {
    return PaymentsTableCompanion(
      id: Value(p.id),
      remoteId: Value(p.remoteId),
      bookingId: Value(p.bookingId),
      kind: Value(p.kind.name),
      amount: Value(p.amount),
      method: Value(p.method),
      note: Value(p.note),
      paidAt: Value(p.paidAt),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      pending: Value(pending),
    );
  }

  PackagesTableCompanion _packageToCompanion(
    Package p, {
    required bool pending,
  }) {
    return PackagesTableCompanion(
      id: Value(p.id),
      remoteId: Value(p.remoteId),
      studioId: Value(p.studioId),
      name: Value(p.name),
      basePrice: Value(p.basePrice),
      coverageHours: Value(p.coverageHours),
      extraHourRate: Value(p.extraHourRate),
      inclusionsJson: Value(_encodeJsonStringList(p.inclusions)),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      pending: Value(pending),
    );
  }

  StatusHistoryTableCompanion _statusHistoryToCompanion(
    StatusHistoryEntry e, {
    required bool pending,
  }) {
    return StatusHistoryTableCompanion(
      id: Value(e.id),
      remoteId: Value(e.remoteId),
      bookingId: Value(e.bookingId),
      fromStatus: Value(e.fromStatus.name),
      toStatus: Value(e.toStatus.name),
      changedByUserId: Value(e.changedByUserId),
      note: Value(e.note),
      at: Value(e.at),
      pending: Value(pending),
    );
  }

  ReEditRequestsTableCompanion _reEditToCompanion(
    ReEditRequest r, {
    required bool pending,
  }) {
    return ReEditRequestsTableCompanion(
      id: Value(r.id),
      remoteId: Value(r.remoteId),
      bookingId: Value(r.bookingId),
      round: Value(r.round),
      editorUserId: Value(r.editorUserId),
      deadline: Value(r.deadline),
      referenceImageUrlsJson: Value(
        _encodeJsonStringList(r.referenceImageUrls),
      ),
      notes: Value(r.notes),
      status: Value(r.status.name),
      requestedByUserId: Value(r.requestedByUserId),
      requestedAt: Value(r.requestedAt),
      updatedAt: Value(r.updatedAt),
      pending: Value(pending),
    );
  }

  TaskProgressTableCompanion _taskProgressToCompanion(
    TaskProgress t, {
    required bool pending,
  }) {
    return TaskProgressTableCompanion(
      bookingId: Value(t.bookingId),
      userId: Value(t.userId),
      percentage: Value(t.percentage),
      note: Value(t.note),
      updatedAt: Value(t.updatedAt),
      pending: Value(pending),
    );
  }

  // ── JSON helpers ────────────────────────────────────────────────────

  String? _encodeJsonMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return jsonEncode(map);
  }

  Map<String, dynamic>? _decodeJsonMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Corrupt blob — return null so the UI renders an empty section
      // rather than crashing on a single bad row.
    }
    return null;
  }

  String? _encodeJsonStringList(List<String>? list) {
    if (list == null) return null;
    return jsonEncode(list);
  }

  List<String>? _decodeJsonStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e == null ? '' : e.toString())
            .toList(growable: false);
      }
    } catch (_) {
      // Fall through to null on corrupt data.
    }
    return null;
  }
}
