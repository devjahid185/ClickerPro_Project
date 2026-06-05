// Shared in-memory database setup helpers for DAO tests.
//
// Every DAO test boots a fresh `AppDatabase.forTesting(NativeDatabase.memory())`
// in `setUp` and tears it down in `tearDown`. The helpers here just compose a
// few Companion factories so the body of each test stays focused on what it is
// asserting rather than on Drift boilerplate.

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Boots a fresh in-memory [AppDatabase] for a test.
AppDatabase makeMemoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

// ───────────────────────── Booking fixture builder ─────────────────────────

BookingsTableCompanion booking({
  required String id,
  required String studioId,
  required String createdByUserId,
  String? title,
  String eventType = 'wedding',
  DateTime? date,
  String startTime = '10:00',
  String endTime = '18:00',
  String shift = 'day',
  String status = 'pending',
}) {
  return BookingsTableCompanion.insert(
    id: id,
    studioId: studioId,
    createdByUserId: createdByUserId,
    title: title ?? 'Booking $id',
    eventType: eventType,
    date: date ?? DateTime(2025, 1, 15),
    startTime: startTime,
    endTime: endTime,
    shift: shift,
    status: Value(status),
  );
}

AssignmentsTableCompanion assignment({
  required String id,
  required String bookingId,
  required String userId,
  String role = 'photographer',
  double payout = 0,
}) {
  return AssignmentsTableCompanion.insert(
    id: id,
    bookingId: bookingId,
    userId: userId,
    role: role,
    payout: Value(payout),
  );
}

ClientsTableCompanion client({
  required String id,
  required String studioId,
  required String name,
  required String phone,
  String? email,
}) {
  return ClientsTableCompanion.insert(
    id: id,
    studioId: studioId,
    name: name,
    phone: phone,
    email: Value(email),
  );
}

PaymentsTableCompanion payment({
  required String id,
  required String bookingId,
  required String kind,
  required double amount,
}) {
  return PaymentsTableCompanion.insert(
    id: id,
    bookingId: bookingId,
    kind: kind,
    amount: amount,
  );
}

PackagesTableCompanion package({
  required String id,
  required String studioId,
  required String name,
  required double basePrice,
}) {
  return PackagesTableCompanion.insert(
    id: id,
    studioId: studioId,
    name: name,
    basePrice: basePrice,
  );
}

StatusHistoryTableCompanion statusHistory({
  required String id,
  required String bookingId,
  required String fromStatus,
  required String toStatus,
  required String changedByUserId,
  DateTime? at,
  bool pending = false,
}) {
  return StatusHistoryTableCompanion.insert(
    id: id,
    bookingId: bookingId,
    fromStatus: fromStatus,
    toStatus: toStatus,
    changedByUserId: changedByUserId,
    at: at ?? DateTime(2025, 1, 1, 12),
    pending: Value(pending),
  );
}

ReEditRequestsTableCompanion reEdit({
  required String id,
  required String bookingId,
  required int round,
  required String requestedByUserId,
  DateTime? deadline,
  String status = 'pending',
}) {
  return ReEditRequestsTableCompanion.insert(
    id: id,
    bookingId: bookingId,
    round: round,
    deadline: deadline ?? DateTime(2025, 2, 1),
    requestedByUserId: requestedByUserId,
    status: Value(status),
  );
}

TaskProgressTableCompanion taskProgress({
  required String bookingId,
  required String userId,
  required int percentage,
  String? note,
}) {
  return TaskProgressTableCompanion.insert(
    bookingId: bookingId,
    userId: userId,
    percentage: percentage,
    note: Value(note),
  );
}

PublicBookingRequestsTableCompanion publicBookingRequest({
  required String id,
  required String studioId,
  required String title,
  required String clientName,
  required String clientPhone,
  String eventType = 'wedding',
  DateTime? date,
  String startTime = '10:00',
  String endTime = '18:00',
  String shift = 'day',
  DateTime? submittedAt,
  String status = 'pending',
}) {
  return PublicBookingRequestsTableCompanion.insert(
    id: id,
    studioId: studioId,
    title: title,
    eventType: eventType,
    date: date ?? DateTime(2025, 3, 1),
    startTime: startTime,
    endTime: endTime,
    shift: shift,
    clientName: clientName,
    clientPhone: clientPhone,
    submittedAt: submittedAt ?? DateTime(2025, 2, 25, 9),
    status: Value(status),
  );
}
