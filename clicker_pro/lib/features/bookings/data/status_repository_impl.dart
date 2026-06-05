// lib/features/bookings/data/status_repository_impl.dart
//
// Status transition repository: gates transitions through
// `BookingStatusMachine`, commits an append-only `StatusHistoryEntry`
// locally before any network call, and reconciles 409 conflicts by
// dropping the local pending row, adopting the server's status, and
// emitting a non-blocking `StatusConflictEvent`.
//
// The `statusConflictStream` is a broadcast `StreamController` so any
// number of UI consumers can subscribe without contention.

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/booking_status/booking_status.dart';
import '../../../core/booking_status/booking_status_machine.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/bookings_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/status_history_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/role_policy.dart';
import '../domain/status_history_entry.dart';
import '../domain/status_repository.dart';
import 'booking_api.dart';
import 'booking_api_exceptions.dart';

class StatusRepositoryImpl implements StatusRepository {
  StatusRepositoryImpl({required BookingApi api, required AppDatabase db})
    : _api = api,
      _db = db,
      _conflictController = StreamController<StatusConflictEvent>.broadcast();

  final BookingApi _api;
  final AppDatabase _db;
  final StreamController<StatusConflictEvent> _conflictController;

  BookingsDao get _bookings => _db.bookingsDao;
  StatusHistoryDao get _history => _db.statusHistoryDao;
  OutboxDao get _outbox => _db.outboxDao;

  StatusHistoryEntry _rowToEntry(StatusHistoryEntryRow r) => StatusHistoryEntry(
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

  @override
  Stream<List<StatusHistoryEntry>> watchHistory(String bookingId) {
    return _history
        .watchByBooking(bookingId)
        .map((rows) => rows.map(_rowToEntry).toList(growable: false));
  }

  @override
  Stream<StatusConflictEvent> get statusConflictStream =>
      _conflictController.stream;

  @override
  Future<void> transition({
    required String bookingId,
    required BookingStatus expectedFrom,
    required BookingStatus to,
    required String changedByUserId,
    required RolePolicy policy,
    String? note,
  }) async {
    if (!BookingStatusMachine.canTransition(policy.role, expectedFrom, to)) {
      throw StatusTransitionDeniedException(
        role: policy.role,
        from: expectedFrom,
        to: to,
      );
    }

    final now = DateTime.now();
    // Simple, monotonic local id. Microsecond precision is sufficient
    // since a single user cannot trigger two transitions in the same
    // microsecond, and we don't want to drag in a UUID dependency just
    // for this.
    final entryId = 'sh-$bookingId-${now.microsecondsSinceEpoch}';

    final entry = StatusHistoryEntry(
      id: entryId,
      bookingId: bookingId,
      fromStatus: expectedFrom,
      toStatus: to,
      changedByUserId: changedByUserId,
      note: note,
      at: now,
      pending: true,
    );

    // Local-first commit: insert the history row and update the
    // booking's status in a single transaction so the UI flips
    // atomically.
    await _db.transaction(() async {
      await _history.append(_entryToCompanion(entry, pending: true));
      await (_db.update(
        _db.bookingsTable,
      )..where((t) => t.id.equals(bookingId))).write(
        BookingsTableCompanion(
          status: Value(to.name),
          updatedAt: Value(now),
          pending: const Value(true),
        ),
      );
    });

    // Look up the booking's remoteId so we know whether the API can be
    // hit directly or whether the work has to be deferred until the
    // parent booking lands a remoteId.
    final bookingRow = await _bookings.watchById(bookingId).first;
    final bookingRemoteId = bookingRow?.remoteId;

    if (bookingRemoteId == null) {
      // Booking still pending sync. The outbox worker will drain the
      // statusHistory entry once the booking has a remoteId.
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'statusHistory',
          entityId: entry.id,
          op: 'create',
          payloadJson: jsonEncode({
            'bookingLocalId': bookingId,
            'fromStatus': expectedFrom.name,
            'toStatus': to.name,
            'changedByUserId': changedByUserId,
            'note': ?note,
            'at': now.toIso8601String(),
            'entryId': entry.id,
          }),
        ),
      );
      return;
    }

    try {
      final remote = await _api.transitionStatus(
        remoteId: bookingRemoteId,
        from: expectedFrom,
        to: to,
        note: note,
      );
      // Stamp the local rows with remote ids + clear pending flags.
      await _history.markSynced(entry.id, remoteId: remote.entry.id);
      await _bookings.markSynced(
        bookingId,
        remoteId: bookingRemoteId,
        updatedAt: remote.event.updatedAt,
      );
    } on StatusConflictException catch (conflict) {
      // 409: server says its own status is `conflict.serverStatus`; our
      // local pending row is now poison. Drop it, adopt the server's
      // status, and surface the conflict so the UI can SnackBar it.
      await _history.deletePendingForBooking(
        bookingId,
        fromStatus: expectedFrom.name,
        toStatus: to.name,
      );
      await (_db.update(
        _db.bookingsTable,
      )..where((t) => t.id.equals(bookingId))).write(
        BookingsTableCompanion(
          status: Value(conflict.serverStatus.name),
          updatedAt: Value(DateTime.now()),
          pending: const Value(false),
        ),
      );
      _conflictController.add(
        StatusConflictEvent(
          bookingId: bookingId,
          serverStatus: conflict.serverStatus,
          attemptedTo: to,
        ),
      );
    } catch (e, st) {
      AppLogger.w('status', 'transition remote failed; queued in outbox: $e');
      AppLogger.e('status', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'statusHistory',
          entityId: entry.id,
          op: 'create',
          payloadJson: jsonEncode({
            'bookingLocalId': bookingId,
            'bookingRemoteId': bookingRemoteId,
            'fromStatus': expectedFrom.name,
            'toStatus': to.name,
            'changedByUserId': changedByUserId,
            'note': ?note,
            'at': now.toIso8601String(),
            'entryId': entry.id,
          }),
        ),
      );
    }
  }

  StatusHistoryTableCompanion _entryToCompanion(
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

  /// Releases the broadcast controller. Callers wire this through
  /// `ref.onDispose` so the stream closes cleanly when the provider
  /// recreates the repository.
  Future<void> dispose() => _conflictController.close();
}
