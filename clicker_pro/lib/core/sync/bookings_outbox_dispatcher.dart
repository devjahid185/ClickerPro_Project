// lib/core/sync/bookings_outbox_dispatcher.dart
//
// Dispatches a single OutboxItem for the bookings module to its remote
// API counterpart and mirrors the result back into Drift.
//
// Each entity type lives behind a dedicated `_drain<Entity>` method. The
// public [drain] entry-point picks the right one by `OutboxRow.entityType`
// and returns a [DispatchResult] the worker uses to decide whether to
// delete the row, advance its retry counter, or surface a manual-retry
// flag.
//
// Conflict policy:
//   • Tier A (booking, client, assignment, payment, package, taskProgress)
//     — last-write-wins. On 2xx, the local row's `pending` flag flips and
//     `remoteId` / `updatedAt` are stamped from the server response.
//     On 4xx (non-409), the row is marked manual_retry; the user can
//     decide whether to discard or retry.
//   • Tier C (statusHistory, reEditStatus) — append-only. Successful
//     drains stamp `remoteId`; the row is never updated by reconciliation.
//   • Status conflict (HTTP 409 from the status-transition endpoint)
//     drops the local pending statusHistory row, refreshes the booking
//     from the server, and emits a `StatusConflictEvent` on the existing
//     conflict stream so the UI can SnackBar it.
//
// The dispatcher is deliberately stateless: every call receives the
// row to drain and returns a result. The worker owns the loop, retry
// schedule, and connectivity gating.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:drift/drift.dart' show Value;

import '../../features/bookings/data/assignment_api.dart';
import '../../features/bookings/data/booking_api.dart';
import '../../features/bookings/data/booking_api_exceptions.dart';
import '../../features/bookings/data/client_api.dart';
import '../../features/bookings/data/package_api.dart';
import '../../features/bookings/data/payment_api.dart';
import '../../features/bookings/data/re_edit_api.dart';
import '../../features/bookings/data/task_progress_api.dart';
import '../../features/bookings/domain/assignment.dart';
import '../../features/bookings/domain/assignment_role.dart';
import '../../features/bookings/domain/booking.dart';
import '../../features/bookings/domain/client.dart';
import '../../features/bookings/domain/event_type.dart';
import '../../features/bookings/domain/package.dart';
import '../../features/bookings/domain/payment.dart';
import '../../features/bookings/domain/payment_kind.dart';
import '../../features/bookings/domain/re_edit_request.dart';
import '../../features/bookings/domain/re_edit_status.dart';
import '../../features/bookings/domain/shift.dart';
import '../../features/bookings/domain/status_repository.dart';
import '../../features/bookings/domain/task_progress.dart';
import '../booking_status/booking_status.dart';
import '../db/app_database.dart';
import '../db/daos/assignments_dao.dart';
import '../db/daos/bookings_dao.dart';
import '../db/daos/clients_dao.dart';
import '../db/daos/packages_dao.dart';
import '../db/daos/payments_dao.dart';
import '../db/daos/re_edit_requests_dao.dart';
import '../db/daos/status_history_dao.dart';
import '../db/daos/task_progress_dao.dart';
import '../logging/app_logger.dart';
import '../network/api_exception.dart';

/// Outcome of a dispatch attempt. The worker translates this enum into
/// the right Drift mutation (delete, mark-attempt, mark-manual-retry).
enum DispatchOutcome {
  /// 2xx — the row should be removed from the outbox.
  success,

  /// 5xx / network failure — bump attempts + schedule next retry.
  retry,

  /// Non-409 4xx — mark `manual_retry` and stop auto-retry.
  manualRetry,

  /// 409 from the status-transition endpoint — already reconciled by
  /// the dispatcher (booking refreshed, conflict event emitted). The
  /// row should be removed from the outbox.
  statusConflictResolved,
}

/// Result returned to the worker.
class DispatchResult {
  const DispatchResult(this.outcome, {this.error});
  final DispatchOutcome outcome;
  final String? error;
}

class BookingsOutboxDispatcher {
  BookingsOutboxDispatcher({
    required AppDatabase db,
    required BookingApi bookingApi,
    required ClientApi clientApi,
    required AssignmentApi assignmentApi,
    required PaymentApi paymentApi,
    required PackageApi packageApi,
    required ReEditApi reEditApi,
    required TaskProgressApi taskProgressApi,
    required StreamSink<StatusConflictEvent> conflictSink,
  }) : _db = db,
       _bookingApi = bookingApi,
       _clientApi = clientApi,
       _assignmentApi = assignmentApi,
       _paymentApi = paymentApi,
       _packageApi = packageApi,
       _reEditApi = reEditApi,
       _taskProgressApi = taskProgressApi,
       _conflictSink = conflictSink;

  final AppDatabase _db;
  final BookingApi _bookingApi;
  final ClientApi _clientApi;
  final AssignmentApi _assignmentApi;
  final PaymentApi _paymentApi;
  final PackageApi _packageApi;
  final ReEditApi _reEditApi;
  final TaskProgressApi _taskProgressApi;
  final StreamSink<StatusConflictEvent> _conflictSink;

  BookingsDao get _bookings => _db.bookingsDao;
  ClientsDao get _clients => _db.clientsDao;
  AssignmentsDao get _assignments => _db.assignmentsDao;
  PaymentsDao get _payments => _db.paymentsDao;
  PackagesDao get _packages => _db.packagesDao;
  StatusHistoryDao get _history => _db.statusHistoryDao;
  ReEditRequestsDao get _reEdits => _db.reEditRequestsDao;
  TaskProgressDao get _taskProgress => _db.taskProgressDao;

  /// Routes a single outbox row to its entity-specific drain handler.
  Future<DispatchResult> drain(OutboxRow row) async {
    try {
      switch (row.entityType) {
        case 'booking':
          return await _drainBooking(row);
        case 'client':
          return await _drainClient(row);
        case 'assignment':
          return await _drainAssignment(row);
        case 'payment':
          return await _drainPayment(row);
        case 'package':
          return await _drainPackage(row);
        case 'statusHistory':
          return await _drainStatusHistory(row);
        case 'reEditRequest':
          return await _drainReEditRequest(row);
        case 'reEditStatus':
          return await _drainReEditStatus(row);
        case 'taskProgress':
          return await _drainTaskProgress(row);
        default:
          // Unknown entity type — leave it for someone else (foundation
          // entity types like `user` / `gear` are handled elsewhere).
          return const DispatchResult(DispatchOutcome.retry);
      }
    } on ApiException catch (e) {
      // 4xx (non-409) is a permanent failure for this payload — the
      // user must intervene. 5xx / network is transient.
      if (e.isNetwork || (e.statusCode >= 500 && e.statusCode < 600)) {
        return DispatchResult(DispatchOutcome.retry, error: e.message);
      }
      return DispatchResult(
        DispatchOutcome.manualRetry,
        error: 'HTTP ${e.statusCode}: ${e.message}',
      );
    } on SocketException catch (e) {
      // Raw transport failure (no response) — transient, safe to retry.
      return DispatchResult(DispatchOutcome.retry, error: e.message);
    } on TimeoutException catch (e) {
      return DispatchResult(
        DispatchOutcome.retry,
        error: e.message ?? 'timeout',
      );
    } catch (e, st) {
      // Anything else = a programming/parse error, NOT a transient
      // network failure. Blind-retrying these is dangerous: a create that
      // succeeded server-side but failed to parse would be re-POSTed on
      // every retry, creating duplicate rows on the server. Park the row
      // for manual retry instead.
      AppLogger.e('outbox', e, st);
      return DispatchResult(
        DispatchOutcome.manualRetry,
        error: 'Unexpected error: $e',
      );
    }
  }

  // ────────────────────────── Tier A: booking ──────────────────────────

  Future<DispatchResult> _drainBooking(OutboxRow row) async {
    final localId = row.entityId;
    final bookingRow = await _bookings.watchById(localId).first;
    switch (row.op) {
      case 'create':
      case 'update':
        if (bookingRow == null) {
          // Local row has vanished (likely a delete-while-pending). Drop
          // the outbox entry; nothing to push.
          return const DispatchResult(DispatchOutcome.success);
        }
        final booking = _bookingFromRow(bookingRow);
        final remote = bookingRow.remoteId == null
            ? await _bookingApi.create(booking)
            : await _bookingApi.patch(bookingRow.remoteId!, booking.toJson());
        await _bookings.markSynced(
          localId,
          remoteId: remote.remoteId ?? remote.id,
          updatedAt: remote.updatedAt,
        );
        return const DispatchResult(DispatchOutcome.success);
      case 'delete':
        final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        final remoteId = payload['remoteId'] as String?;
        if (remoteId != null) {
          await _bookingApi.delete(remoteId);
        }
        // Hard-delete the local row if the user hasn't already.
        if (bookingRow != null) {
          await _bookings.deleteById(localId);
        }
        return const DispatchResult(DispatchOutcome.success);
      default:
        return const DispatchResult(DispatchOutcome.success);
    }
  }

  // ────────────────────────── Tier A: client ──────────────────────────

  Future<DispatchResult> _drainClient(OutboxRow row) async {
    final clientRow = await _clients.watchById(row.entityId).first;
    if (clientRow == null) return const DispatchResult(DispatchOutcome.success);
    final client = _clientFromRow(clientRow);
    final remote = clientRow.remoteId == null
        ? await _clientApi.create(client)
        : await _clientApi.patch(clientRow.remoteId!, client.toJson());
    await _clients.upsert(_clientToCompanion(remote, pending: false));
    return const DispatchResult(DispatchOutcome.success);
  }

  // ────────────────────────── Tier A: assignment ──────────────────────────

  Future<DispatchResult> _drainAssignment(OutboxRow row) async {
    final assignmentRow = await _findAssignmentRow(row.entityId);
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    if (row.op == 'delete') {
      final parentBookingId =
          assignmentRow?.bookingId ?? payload['bookingId'] as String?;
      if (parentBookingId == null) {
        return const DispatchResult(DispatchOutcome.success);
      }
      final bookingRow = await _bookings.watchById(parentBookingId).first;
      final bookingRemoteId = bookingRow?.remoteId;
      final assignmentRemoteId =
          assignmentRow?.remoteId ?? payload['remoteId'] as String?;
      if (bookingRemoteId == null || assignmentRemoteId == null) {
        // Parent booking still pending sync; defer.
        return const DispatchResult(DispatchOutcome.retry);
      }
      await _assignmentApi.delete(bookingRemoteId, assignmentRemoteId);
      return const DispatchResult(DispatchOutcome.success);
    }

    if (assignmentRow == null) {
      return const DispatchResult(DispatchOutcome.success);
    }
    final assignment = _assignmentFromRow(assignmentRow);
    final bookingRow = await _bookings.watchById(assignment.bookingId).first;
    final bookingRemoteId = bookingRow?.remoteId;
    if (bookingRemoteId == null) {
      // Booking not yet synced; the create/update will land once it is.
      return const DispatchResult(DispatchOutcome.retry);
    }
    final remote = row.op == 'create'
        ? await _assignmentApi.create(bookingRemoteId, assignment)
        : await _assignmentApi.patch(
            bookingRemoteId,
            assignment.remoteId ?? assignment.id,
            assignment.toJson(),
          );
    await _assignments.upsert(_assignmentToCompanion(remote, pending: false));
    return const DispatchResult(DispatchOutcome.success);
  }

  // ────────────────────────── Tier A: payment ──────────────────────────

  Future<DispatchResult> _drainPayment(OutboxRow row) async {
    final paymentRow = await _findPaymentRow(row.entityId);
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    if (row.op == 'delete') {
      final parentBookingId =
          paymentRow?.bookingId ?? payload['bookingId'] as String?;
      if (parentBookingId == null) {
        return const DispatchResult(DispatchOutcome.success);
      }
      final bookingRow = await _bookings.watchById(parentBookingId).first;
      final bookingRemoteId = bookingRow?.remoteId;
      final paymentRemoteId =
          paymentRow?.remoteId ?? payload['remoteId'] as String?;
      if (bookingRemoteId == null || paymentRemoteId == null) {
        return const DispatchResult(DispatchOutcome.retry);
      }
      await _paymentApi.delete(bookingRemoteId, paymentRemoteId);
      return const DispatchResult(DispatchOutcome.success);
    }

    if (paymentRow == null) {
      return const DispatchResult(DispatchOutcome.success);
    }
    final payment = _paymentFromRow(paymentRow);
    final bookingRow = await _bookings.watchById(payment.bookingId).first;
    final bookingRemoteId = bookingRow?.remoteId;
    if (bookingRemoteId == null) {
      return const DispatchResult(DispatchOutcome.retry);
    }
    final remote = row.op == 'create'
        ? await _paymentApi.create(bookingRemoteId, payment)
        : await _paymentApi.patch(
            bookingRemoteId,
            payment.remoteId ?? payment.id,
            payment.toJson(),
          );
    await _payments.upsert(_paymentToCompanion(remote, pending: false));
    return const DispatchResult(DispatchOutcome.success);
  }

  // ────────────────────────── Tier A: package ──────────────────────────

  Future<DispatchResult> _drainPackage(OutboxRow row) async {
    final packages = await _packages.watchAll().first;
    final packageRow = packages
        .where((p) => p.id == row.entityId)
        .cast<PackageRow?>()
        .firstWhere((_) => true, orElse: () => null);
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    if (row.op == 'delete') {
      final remoteId = packageRow?.remoteId ?? payload['remoteId'] as String?;
      if (remoteId == null) {
        return const DispatchResult(DispatchOutcome.success);
      }
      await _packageApi.delete(remoteId);
      return const DispatchResult(DispatchOutcome.success);
    }
    if (packageRow == null) {
      return const DispatchResult(DispatchOutcome.success);
    }
    final pkg = _packageFromRow(packageRow);
    final remote = packageRow.remoteId == null
        ? await _packageApi.create(pkg)
        : await _packageApi.patch(packageRow.remoteId!, pkg.toJson());
    await _packages.upsert(_packageToCompanion(remote, pending: false));
    return const DispatchResult(DispatchOutcome.success);
  }

  // ────────────────────── Tier C: status history ──────────────────────

  Future<DispatchResult> _drainStatusHistory(OutboxRow row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final bookingLocalId = payload['bookingLocalId'] as String?;
    if (bookingLocalId == null) {
      return const DispatchResult(DispatchOutcome.success);
    }
    final bookingRow = await _bookings.watchById(bookingLocalId).first;
    final bookingRemoteId =
        bookingRow?.remoteId ?? payload['bookingRemoteId'] as String?;
    if (bookingRemoteId == null) {
      // Parent booking still pending sync.
      return const DispatchResult(DispatchOutcome.retry);
    }
    final fromStatus = _statusFromString(payload['fromStatus'] as String);
    final toStatus = _statusFromString(payload['toStatus'] as String);
    final note = payload['note'] as String?;

    try {
      final remote = await _bookingApi.transitionStatus(
        remoteId: bookingRemoteId,
        from: fromStatus,
        to: toStatus,
        note: note,
      );
      await _history.markSynced(row.entityId, remoteId: remote.entry.id);
      // Server may have advanced the booking; reflect back into Drift.
      await _bookings.markSynced(
        bookingLocalId,
        remoteId: bookingRemoteId,
        updatedAt: remote.event.updatedAt,
      );
      return const DispatchResult(DispatchOutcome.success);
    } on StatusConflictException catch (conflict) {
      // 409 — drop the local pending row, adopt server status, emit
      // event so UI can SnackBar it.
      await _history.deletePendingForBooking(
        bookingLocalId,
        fromStatus: fromStatus.name,
        toStatus: toStatus.name,
      );
      await (_db.update(
        _db.bookingsTable,
      )..where((t) => t.id.equals(bookingLocalId))).write(
        BookingsTableCompanion(
          status: Value(conflict.serverStatus.name),
          updatedAt: Value(DateTime.now()),
          pending: const Value(false),
        ),
      );
      _conflictSink.add(
        StatusConflictEvent(
          bookingId: bookingLocalId,
          serverStatus: conflict.serverStatus,
          attemptedTo: toStatus,
        ),
      );
      return const DispatchResult(DispatchOutcome.statusConflictResolved);
    }
  }

  // ────────────────────── Tier C: re-edit status ──────────────────────

  Future<DispatchResult> _drainReEditStatus(OutboxRow row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final reEditRemoteId = payload['reEditRemoteId'] as String?;
    final toStatus = payload['toStatus'] as String;
    if (reEditRemoteId == null) {
      // The re-edit row hasn't been synced yet — defer.
      return const DispatchResult(DispatchOutcome.retry);
    }
    await _reEditApi.updateStatus(
      reEditRemoteId,
      _reEditStatusFromString(toStatus),
    );
    return const DispatchResult(DispatchOutcome.success);
  }

  Future<DispatchResult> _drainReEditRequest(OutboxRow row) async {
    final reEditRow = await _findReEditRow(row.entityId);
    if (reEditRow == null) return const DispatchResult(DispatchOutcome.success);
    final reEdit = _reEditFromRow(reEditRow);
    final bookingRow = await _bookings.watchById(reEdit.bookingId).first;
    final bookingRemoteId = bookingRow?.remoteId;
    if (bookingRemoteId == null) {
      return const DispatchResult(DispatchOutcome.retry);
    }
    final remote = await _reEditApi.create(bookingRemoteId, reEdit);
    await _reEdits.upsert(_reEditToCompanion(remote, pending: false));
    return const DispatchResult(DispatchOutcome.success);
  }

  // ─────────────────────── Tier A: task progress ───────────────────────

  Future<DispatchResult> _drainTaskProgress(OutboxRow row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final bookingLocalId = payload['bookingId'] as String?;
    final percentage = (payload['percentage'] as num?)?.toInt() ?? 0;
    final note = payload['note'] as String?;
    if (bookingLocalId == null) {
      return const DispatchResult(DispatchOutcome.success);
    }
    final bookingRow = await _bookings.watchById(bookingLocalId).first;
    final bookingRemoteId = bookingRow?.remoteId;
    if (bookingRemoteId == null) {
      return const DispatchResult(DispatchOutcome.retry);
    }
    final remote = await _taskProgressApi.upsert(
      bookingRemoteId,
      percentage: percentage,
      note: note,
    );
    await _taskProgress.upsert(
      _taskProgressToCompanion(remote, pending: false),
    );
    return const DispatchResult(DispatchOutcome.success);
  }

  // ────────────────────────── Helpers ──────────────────────────

  Future<AssignmentRow?> _findAssignmentRow(String id) async {
    final rows = await _db.select(_db.assignmentsTable).get();
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<PaymentRow?> _findPaymentRow(String id) async {
    final rows = await _db.select(_db.paymentsTable).get();
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<ReEditRequestRow?> _findReEditRow(String id) async {
    final rows = await _db.select(_db.reEditRequestsTable).get();
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ────────────── Drift row → Domain model conversions ──────────────

  Booking _bookingFromRow(BookingRow r) => Booking(
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
    // Carry the typed client name/phone through to the server so a
    // booking made offline (with no separate synced Client row) can be
    // created — the backend find-or-creates the client from these.
    clientName: r.clientName,
    clientPhone: r.clientPhone,
    packageId: r.packageId,
    customPrice: r.customPrice,
    coverageHours: r.coverageHours,
    extraHourRate: r.extraHourRate,
    driveLink: r.driveLink,
    notes: r.notes,
    chiefPhotographerUserId: r.chiefPhotographerUserId,
    chiefHours: r.chiefHours,
    hidePaymentFromTeam: r.hidePaymentFromTeam,
    status: _statusFromString(r.status),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  Client _clientFromRow(ClientRow r) => Client(
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

  Assignment _assignmentFromRow(AssignmentRow r) => Assignment(
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

  Payment _paymentFromRow(PaymentRow r) => Payment(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    kind: PaymentKind.values.firstWhere(
      (k) => k.name == r.kind,
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

  Package _packageFromRow(PackageRow r) => Package(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    name: r.name,
    basePrice: r.basePrice,
    coverageHours: r.coverageHours,
    extraHourRate: r.extraHourRate,
    inclusions: _decodeStringList(r.inclusionsJson),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  ReEditRequest _reEditFromRow(ReEditRequestRow r) => ReEditRequest(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    round: r.round,
    editorUserId: r.editorUserId,
    deadline: r.deadline,
    referenceImageUrls: _decodeStringList(r.referenceImageUrlsJson),
    notes: r.notes,
    status: _reEditStatusFromString(r.status),
    requestedByUserId: r.requestedByUserId,
    requestedAt: r.requestedAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  ClientsTableCompanion _clientToCompanion(Client c, {required bool pending}) =>
      ClientsTableCompanion(
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

  AssignmentsTableCompanion _assignmentToCompanion(
    Assignment a, {
    required bool pending,
  }) => AssignmentsTableCompanion(
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

  PaymentsTableCompanion _paymentToCompanion(
    Payment p, {
    required bool pending,
  }) => PaymentsTableCompanion(
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

  PackagesTableCompanion _packageToCompanion(
    Package p, {
    required bool pending,
  }) => PackagesTableCompanion(
    id: Value(p.id),
    remoteId: Value(p.remoteId),
    studioId: Value(p.studioId),
    name: Value(p.name),
    basePrice: Value(p.basePrice),
    coverageHours: Value(p.coverageHours),
    extraHourRate: Value(p.extraHourRate),
    inclusionsJson: Value(_encodeStringList(p.inclusions)),
    createdAt: Value(p.createdAt),
    updatedAt: Value(p.updatedAt),
    pending: Value(pending),
  );

  ReEditRequestsTableCompanion _reEditToCompanion(
    ReEditRequest r, {
    required bool pending,
  }) => ReEditRequestsTableCompanion(
    id: Value(r.id),
    remoteId: Value(r.remoteId),
    bookingId: Value(r.bookingId),
    round: Value(r.round),
    editorUserId: Value(r.editorUserId),
    deadline: Value(r.deadline),
    referenceImageUrlsJson: Value(_encodeStringList(r.referenceImageUrls)),
    notes: Value(r.notes),
    status: Value(r.status.name),
    requestedByUserId: Value(r.requestedByUserId),
    requestedAt: Value(r.requestedAt),
    updatedAt: Value(r.updatedAt),
    pending: Value(pending),
  );

  TaskProgressTableCompanion _taskProgressToCompanion(
    TaskProgress t, {
    required bool pending,
  }) => TaskProgressTableCompanion(
    bookingId: Value(t.bookingId),
    userId: Value(t.userId),
    percentage: Value(t.percentage),
    note: Value(t.note),
    updatedAt: Value(t.updatedAt),
    pending: Value(pending),
  );

  String? _encodeStringList(List<String>? list) =>
      list == null ? null : jsonEncode(list);

  List<String>? _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e == null ? '' : e.toString())
            .toList(growable: false);
      }
    } catch (_) {
      // Corrupt blob — treat as null.
    }
    return null;
  }

  BookingStatus _statusFromString(String name) {
    for (final s in BookingStatus.values) {
      if (s.name == name) return s;
    }
    return BookingStatus.pending;
  }

  ReEditStatus _reEditStatusFromString(String name) {
    for (final s in ReEditStatus.values) {
      if (s.name == name) return s;
    }
    return ReEditStatus.pending;
  }
}
