// test/bookings/round_trip_serialization_test.dart
//
// Property 9: Round-trip serialization
// For every domain entity {Booking, Client, Assignment, Payment, Package,
// StatusHistoryEntry, ReEditRequest, TaskProgress, PublicBookingRequest}
// AND any valid instance e, the equality `E.fromJson(e.toJson()) == e` holds.
//
// This is a smoke version with hand-crafted instances — full glados-based
// fuzz testing lives in `*_property_test.dart` (deferred for property-test
// expansion in a later wave).

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/features/bookings/domain/assignment.dart';
import 'package:clicker_pro/features/bookings/domain/assignment_role.dart';
import 'package:clicker_pro/features/bookings/domain/booking.dart';
import 'package:clicker_pro/features/bookings/domain/client.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/package.dart';
import 'package:clicker_pro/features/bookings/domain/payment.dart';
import 'package:clicker_pro/features/bookings/domain/payment_kind.dart';
import 'package:clicker_pro/features/bookings/domain/re_edit_request.dart';
import 'package:clicker_pro/features/bookings/domain/re_edit_status.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/bookings/domain/status_history_entry.dart';
import 'package:clicker_pro/features/bookings/domain/task_progress.dart';
import 'package:clicker_pro/features/public_booking/domain/public_booking_request.dart';
import 'package:clicker_pro/features/public_booking/domain/public_booking_request_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Use a fixed timestamp so toIso8601String round-trips exactly.
  final fixed = DateTime.parse('2025-01-15T10:30:00.000Z');

  group('Property 9: Round-trip serialization (Feature: bookings-module)', () {
    test('Booking — fromJson(toJson(b)) == b', () {
      final b = Booking(
        id: 'b1',
        remoteId: 'r1',
        studioId: 's1',
        createdByUserId: 'u1',
        title: 'Wedding shoot',
        eventType: EventType.wedding,
        date: fixed,
        startTime: '09:00',
        endTime: '18:00',
        shift: Shift.day,
        venue: 'Hall A',
        outdoor: true,
        brideName: 'Anika',
        groomName: 'Karim',
        clientId: 'c1',
        packageId: 'p1',
        coverageHours: 8,
        extraHourRate: 1200,
        driveLink: 'https://drive.google.com/x',
        clientRequirements: const {
          'shotList': ['ring', 'bouquet'],
        },
        notes: 'VIP client',
        chiefPhotographerUserId: 'u2',
        chiefHours: 6,
        hidePaymentFromTeam: true,
        status: BookingStatus.confirmed,
        createdAt: fixed,
        updatedAt: fixed,
      );
      expect(Booking.fromJson(b.toJson()), equals(b));
    });

    test('Client — fromJson(toJson(c)) == c', () {
      final c = Client(
        id: 'c1',
        remoteId: 'r1',
        studioId: 's1',
        name: 'কুলসুম',
        phone: '01700000000',
        email: 'k@example.com',
        address: 'Dhaka',
        dob: fixed,
        anniversary: fixed,
        createdAt: fixed,
        updatedAt: fixed,
      );
      expect(Client.fromJson(c.toJson()), equals(c));
    });

    test('Assignment — fromJson(toJson(a)) == a', () {
      final a = Assignment(
        id: 'a1',
        remoteId: 'r1',
        bookingId: 'b1',
        userId: 'u1',
        role: AssignmentRole.cinematographer,
        payout: 5000.0,
        notes: 'Needs gimbal',
        createdAt: fixed,
        updatedAt: fixed,
      );
      expect(Assignment.fromJson(a.toJson()), equals(a));
    });

    test('Payment — fromJson(toJson(p)) == p', () {
      final p = Payment(
        id: 'p1',
        bookingId: 'b1',
        kind: PaymentKind.advance,
        amount: 25000.0,
        method: 'bkash',
        note: 'Booking advance',
        paidAt: fixed,
        createdAt: fixed,
        updatedAt: fixed,
      );
      expect(Payment.fromJson(p.toJson()), equals(p));
    });

    test('Package — fromJson(toJson(p)) == p', () {
      final p = Package(
        id: 'p1',
        studioId: 's1',
        name: 'Diamond Wedding',
        basePrice: 50000.0,
        coverageHours: 8,
        extraHourRate: 1500,
        inclusions: const ['1 photographer', '1 cinematographer'],
        createdAt: fixed,
        updatedAt: fixed,
      );
      expect(Package.fromJson(p.toJson()), equals(p));
    });

    test('StatusHistoryEntry — fromJson(toJson(s)) == s', () {
      final s = StatusHistoryEntry(
        id: 's1',
        bookingId: 'b1',
        fromStatus: BookingStatus.pending,
        toStatus: BookingStatus.confirmed,
        changedByUserId: 'u1',
        note: 'Confirmed by phone',
        at: fixed,
      );
      expect(StatusHistoryEntry.fromJson(s.toJson()), equals(s));
    });

    test('ReEditRequest — fromJson(toJson(r)) == r', () {
      final r = ReEditRequest(
        id: 'r1',
        bookingId: 'b1',
        round: 2,
        editorUserId: 'u3',
        deadline: fixed,
        referenceImageUrls: const ['https://x.com/1', 'https://x.com/2'],
        notes: 'Brighter skin tones',
        status: ReEditStatus.inProgress,
        requestedByUserId: 'u1',
        requestedAt: fixed,
        updatedAt: fixed,
      );
      expect(ReEditRequest.fromJson(r.toJson()), equals(r));
    });

    test('TaskProgress — fromJson(toJson(t)) == t', () {
      final t = TaskProgress(
        bookingId: 'b1',
        userId: 'u1',
        percentage: 65,
        note: 'Editing in progress',
        updatedAt: fixed,
      );
      expect(TaskProgress.fromJson(t.toJson()), equals(t));
    });

    test('PublicBookingRequest — fromJson(toJson(p)) == p', () {
      final p = PublicBookingRequest(
        id: 'p1',
        studioId: 's1',
        title: 'Birthday',
        eventType: EventType.birthday,
        date: fixed,
        startTime: '17:00',
        endTime: '21:00',
        shift: Shift.night,
        venue: 'Garden Hall',
        clientName: 'Rahim',
        clientPhone: '01900000000',
        clientEmail: 'r@example.com',
        notes: 'Surprise event',
        status: PublicBookingRequestStatus.pending,
        submittedAt: fixed,
        updatedAt: fixed,
      );
      expect(PublicBookingRequest.fromJson(p.toJson()), equals(p));
    });
  });
}
