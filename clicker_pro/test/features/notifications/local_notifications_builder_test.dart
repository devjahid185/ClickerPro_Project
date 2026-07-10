// test/features/notifications/local_notifications_builder_test.dart
//
// Covers the offline notification source that keeps the bell useful when
// the backend inbox is unreachable (round-3 item [12]). Verifies the
// upcoming-booking window, message shaping, deeplink, and that terminal /
// out-of-window bookings are excluded.

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/features/bookings/domain/booking.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/notifications/data/local_notifications_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Booking _booking({
  required String id,
  required DateTime date,
  BookingStatus status = BookingStatus.confirmed,
  String title = 'Shoot',
  String? clientName,
  String? venue,
  String startTime = '10:00',
}) {
  final ts = DateTime.parse('2025-01-01T00:00:00.000Z');
  return Booking(
    id: id,
    studioId: 's1',
    createdByUserId: 'u1',
    title: title,
    eventType: EventType.wedding,
    date: date,
    startTime: startTime,
    endTime: '18:00',
    shift: Shift.day,
    clientName: clientName,
    venue: venue,
    status: status,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  final now = DateTime(2026, 7, 9, 12); // fixed "today"
  final today = DateTime(2026, 7, 9);

  group('LocalNotificationsBuilder.fromBookings', () {
    test('includes upcoming non-terminal bookings within the horizon', () {
      final bookings = [
        _booking(id: 'a', date: today, clientName: 'Anika'),
        _booking(
          id: 'b',
          date: today.add(const Duration(days: 1)),
          clientName: 'Karim',
        ),
        _booking(id: 'c', date: today.add(const Duration(days: 6))),
      ];

      final result = LocalNotificationsBuilder.fromBookings(bookings, now: now);

      expect(result.length, 3);
      // Sorted by date ascending → 'a' first.
      expect(result.first.deeplink, '/bookings/a');
      expect(result.first.message, contains('Anika'));
      expect(result.first.message, contains('today'));
      expect(result[1].message, contains('tomorrow'));
      expect(result.last.message, contains('in 6 days'));
    });

    test('excludes past, cancelled, completed, and beyond-horizon bookings', () {
      final bookings = [
        _booking(id: 'past', date: today.subtract(const Duration(days: 1))),
        _booking(
          id: 'cancelled',
          date: today,
          status: BookingStatus.cancelled,
        ),
        _booking(
          id: 'completed',
          date: today,
          status: BookingStatus.completed,
        ),
        _booking(id: 'far', date: today.add(const Duration(days: 30))),
      ];

      final result = LocalNotificationsBuilder.fromBookings(bookings, now: now);

      expect(result, isEmpty);
    });

    test('local notifications are read + carry the local id prefix', () {
      final result = LocalNotificationsBuilder.fromBookings(
        [_booking(id: 'x', date: today)],
        now: now,
      );

      expect(result.single.read, isTrue);
      expect(result.single.id, 'local-booking-x');
      expect(result.single.category, 'OPERATIONS');
    });

    test('falls back to booking title when client name is blank', () {
      final result = LocalNotificationsBuilder.fromBookings(
        [_booking(id: 'x', date: today, title: 'Corporate gig', clientName: '')],
        now: now,
      );

      expect(result.single.message, contains('Corporate gig'));
    });

    test('appends venue when present', () {
      final result = LocalNotificationsBuilder.fromBookings(
        [_booking(id: 'x', date: today, venue: 'Hall A')],
        now: now,
      );

      expect(result.single.message, contains('at Hall A'));
    });
  });
}
