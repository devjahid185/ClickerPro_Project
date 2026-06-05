// test/sync/bookings_outbox_dispatcher_test.dart
//
// Unit tests for the BookingsOutboxDispatcher. Cover the contracts the
// worker depends on:
//
//   • Tier-A booking create / update / delete returns success and
//     mirrors the remote response back into Drift.
//   • Network failure on a Tier-A drain returns `retry`.
//   • 4xx on a Tier-A drain returns `manualRetry`.
//   • A status-history 409 returns `statusConflictResolved` AND emits
//     a `StatusConflictEvent` with the server's status.
//   • An assignment whose parent booking is still pending sync returns
//     `retry` so the worker defers until the parent lands a remoteId.

import 'dart:async';
import 'dart:io';

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/network/api_exception.dart';
import 'package:clicker_pro/core/sync/bookings_outbox_dispatcher.dart';
import 'package:clicker_pro/features/bookings/data/assignment_api.dart';
import 'package:clicker_pro/features/bookings/data/booking_api.dart';
import 'package:clicker_pro/features/bookings/data/booking_api_exceptions.dart';
import 'package:clicker_pro/features/bookings/data/client_api.dart';
import 'package:clicker_pro/features/bookings/data/package_api.dart';
import 'package:clicker_pro/features/bookings/data/payment_api.dart';
import 'package:clicker_pro/features/bookings/data/re_edit_api.dart';
import 'package:clicker_pro/features/bookings/data/task_progress_api.dart';
import 'package:clicker_pro/features/bookings/domain/assignment.dart';
import 'package:clicker_pro/features/bookings/domain/assignment_role.dart';
import 'package:clicker_pro/features/bookings/domain/booking.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/bookings/domain/status_history_entry.dart';
import 'package:clicker_pro/features/bookings/domain/status_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StreamController<StatusConflictEvent> conflicts;
  late _FakeBookingApi bookingApi;
  late _FakeAssignmentApi assignmentApi;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    conflicts = StreamController<StatusConflictEvent>.broadcast();
    bookingApi = _FakeBookingApi();
    assignmentApi = _FakeAssignmentApi();
  });

  tearDown(() async {
    await conflicts.close();
    await db.close();
  });

  BookingsOutboxDispatcher buildDispatcher() => BookingsOutboxDispatcher(
    db: db,
    bookingApi: bookingApi,
    clientApi: _NoOpClientApi(),
    assignmentApi: assignmentApi,
    paymentApi: _NoOpPaymentApi(),
    packageApi: _NoOpPackageApi(),
    reEditApi: _NoOpReEditApi(),
    taskProgressApi: _NoOpTaskProgressApi(),
    conflictSink: conflicts.sink,
  );

  group('booking drain', () {
    test('create succeeds and stamps remoteId', () async {
      // Seed a local pending booking.
      final now = DateTime(2025, 6, 1);
      await db.bookingsDao.upsert(
        BookingsTableCompanion.insert(
          id: 'b1',
          studioId: 'u-owner-1',
          createdByUserId: 'u-owner-1',
          title: 'Booking 1',
          eventType: EventType.wedding.name,
          date: now,
          startTime: '14:00',
          endTime: '20:00',
          shift: Shift.day.name,
          pending: const Value(true),
        ),
      );
      final outboxId = await db.outboxDao.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'booking',
          entityId: 'b1',
          op: 'create',
          payloadJson: '{}',
        ),
      );
      final outboxRow = (await db.outboxDao.watchPending().first).single;
      expect(outboxRow.id, outboxId);

      bookingApi.createResponse = Booking(
        id: 'b1',
        remoteId: 'remote-1',
        studioId: 'u-owner-1',
        createdByUserId: 'u-owner-1',
        title: 'Booking 1',
        eventType: EventType.wedding,
        date: now,
        startTime: '14:00',
        endTime: '20:00',
        shift: Shift.day,
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final result = await buildDispatcher().drain(outboxRow);
      expect(result.outcome, DispatchOutcome.success);

      final stored = await db.bookingsDao.watchById('b1').first;
      expect(stored?.remoteId, 'remote-1');
      expect(stored?.pending, isFalse);
    });

    test('network failure returns retry', () async {
      final now = DateTime(2025, 6, 1);
      await db.bookingsDao.upsert(
        BookingsTableCompanion.insert(
          id: 'b1',
          studioId: 'u-owner-1',
          createdByUserId: 'u-owner-1',
          title: 'Booking 1',
          eventType: EventType.wedding.name,
          date: now,
          startTime: '14:00',
          endTime: '20:00',
          shift: Shift.day.name,
        ),
      );
      await db.outboxDao.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'booking',
          entityId: 'b1',
          op: 'create',
          payloadJson: '{}',
        ),
      );
      final row = (await db.outboxDao.watchPending().first).single;

      bookingApi.createError = const SocketException('offline');
      final result = await buildDispatcher().drain(row);
      expect(result.outcome, DispatchOutcome.retry);
    });

    test('4xx returns manualRetry', () async {
      final now = DateTime(2025, 6, 1);
      await db.bookingsDao.upsert(
        BookingsTableCompanion.insert(
          id: 'b1',
          studioId: 'u-owner-1',
          createdByUserId: 'u-owner-1',
          title: 'Booking 1',
          eventType: EventType.wedding.name,
          date: now,
          startTime: '14:00',
          endTime: '20:00',
          shift: Shift.day.name,
        ),
      );
      await db.outboxDao.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'booking',
          entityId: 'b1',
          op: 'create',
          payloadJson: '{}',
        ),
      );
      final row = (await db.outboxDao.watchPending().first).single;

      bookingApi.createError = ApiException(
        statusCode: 400,
        message: 'Validation failed',
      );
      final result = await buildDispatcher().drain(row);
      expect(result.outcome, DispatchOutcome.manualRetry);
    });
  });

  group('status-history drain', () {
    test('409 conflict resolves and emits a StatusConflictEvent', () async {
      final now = DateTime(2025, 6, 1);
      await db.bookingsDao.upsert(
        BookingsTableCompanion.insert(
          id: 'b1',
          studioId: 'u-owner-1',
          createdByUserId: 'u-owner-1',
          title: 'Booking 1',
          eventType: EventType.wedding.name,
          date: now,
          startTime: '14:00',
          endTime: '20:00',
          shift: Shift.day.name,
          remoteId: const Value('remote-1'),
          status: const Value('pending'),
        ),
      );
      await db.statusHistoryDao.append(
        StatusHistoryTableCompanion.insert(
          id: 'sh-1',
          bookingId: 'b1',
          fromStatus: 'pending',
          toStatus: 'confirmed',
          changedByUserId: 'u-owner-1',
          at: now,
          pending: const Value(true),
        ),
      );
      await db.outboxDao.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'statusHistory',
          entityId: 'sh-1',
          op: 'create',
          payloadJson:
              '{"bookingLocalId":"b1","bookingRemoteId":"remote-1",'
              '"fromStatus":"pending","toStatus":"confirmed",'
              '"changedByUserId":"u-owner-1","at":"${now.toIso8601String()}",'
              '"entryId":"sh-1"}',
        ),
      );
      final row = (await db.outboxDao.watchPending().first).single;

      bookingApi.transitionStatusError = StatusConflictException(
        serverStatus: BookingStatus.cancelled,
        message: 'conflict',
      );

      final received = <StatusConflictEvent>[];
      final sub = conflicts.stream.listen(received.add);

      final result = await buildDispatcher().drain(row);
      // Allow the broadcast event to flush.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(result.outcome, DispatchOutcome.statusConflictResolved);
      expect(received, hasLength(1));
      expect(received.single.serverStatus, BookingStatus.cancelled);
      expect(received.single.attemptedTo, BookingStatus.confirmed);

      // Booking now reflects the server's status; the local pending
      // history row was dropped.
      final booking = await db.bookingsDao.watchById('b1').first;
      expect(booking?.status, 'cancelled');
      final history = await db.statusHistoryDao.watchByBooking('b1').first;
      expect(history, isEmpty);
    });
  });

  group('assignment drain', () {
    test('parent booking has no remoteId yet — returns retry', () async {
      final now = DateTime(2025, 6, 1);
      await db.bookingsDao.upsert(
        BookingsTableCompanion.insert(
          id: 'b1',
          studioId: 'u-owner-1',
          createdByUserId: 'u-owner-1',
          title: 'Booking 1',
          eventType: EventType.wedding.name,
          date: now,
          startTime: '14:00',
          endTime: '20:00',
          shift: Shift.day.name,
          // no remoteId — pending sync.
        ),
      );
      await db.assignmentsDao.upsert(
        AssignmentsTableCompanion.insert(
          id: 'a1',
          bookingId: 'b1',
          userId: 'u-photog-1',
          role: AssignmentRole.photographer.name,
        ),
      );
      await db.outboxDao.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'assignment',
          entityId: 'a1',
          op: 'create',
          payloadJson: '{"bookingId":"b1"}',
        ),
      );
      final row = (await db.outboxDao.watchPending().first).single;

      final result = await buildDispatcher().drain(row);
      expect(result.outcome, DispatchOutcome.retry);
      // The fake API was never called because the parent booking had
      // no remoteId.
      expect(assignmentApi.createCalls, isEmpty);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Fakes — implement the API surfaces with `noSuchMethod` so unexpected
// calls fail loudly in the test, and only the methods exercised by the
// dispatcher carry behaviour.
// ─────────────────────────────────────────────────────────────────────

class _FakeBookingApi implements BookingApi {
  Booking? createResponse;
  Object? createError;
  Object? transitionStatusError;

  @override
  Future<Booking> create(Booking booking) async {
    if (createError != null) throw createError!;
    return createResponse!;
  }

  @override
  Future<Booking> patch(String remoteId, Map<String, dynamic> partial) async {
    if (createError != null) throw createError!;
    return createResponse!;
  }

  @override
  Future<void> delete(String remoteId) async {}

  @override
  Future<({Booking event, StatusHistoryEntry entry})> transitionStatus({
    required String remoteId,
    required BookingStatus from,
    required BookingStatus to,
    String? note,
  }) async {
    if (transitionStatusError != null) throw transitionStatusError!;
    final now = DateTime(2025, 6, 1);
    return (
      event: Booking(
        id: 'b1',
        remoteId: remoteId,
        studioId: 'u-owner-1',
        createdByUserId: 'u-owner-1',
        title: 'Booking 1',
        eventType: EventType.wedding,
        date: now,
        startTime: '14:00',
        endTime: '20:00',
        shift: Shift.day,
        status: to,
        createdAt: now,
        updatedAt: now,
      ),
      entry: StatusHistoryEntry(
        id: 'remote-sh-1',
        bookingId: 'b1',
        fromStatus: from,
        toStatus: to,
        changedByUserId: 'u-owner-1',
        at: now,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected BookingApi.${invocation.memberName} call in test',
    );
  }
}

class _FakeAssignmentApi implements AssignmentApi {
  final List<Assignment> createCalls = [];

  @override
  Future<Assignment> create(
    String bookingRemoteId,
    Assignment assignment,
  ) async {
    createCalls.add(assignment);
    return assignment.copyWith(remoteId: 'remote-${assignment.id}');
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected AssignmentApi.${invocation.memberName} call',
    );
  }
}

class _NoOpClientApi implements ClientApi {
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected ClientApi.${invocation.memberName} call',
    );
  }
}

class _NoOpPaymentApi implements PaymentApi {
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected PaymentApi.${invocation.memberName} call',
    );
  }
}

class _NoOpPackageApi implements PackageApi {
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected PackageApi.${invocation.memberName} call',
    );
  }
}

class _NoOpReEditApi implements ReEditApi {
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected ReEditApi.${invocation.memberName} call',
    );
  }
}

class _NoOpTaskProgressApi implements TaskProgressApi {
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected TaskProgressApi.${invocation.memberName} call',
    );
  }
}
