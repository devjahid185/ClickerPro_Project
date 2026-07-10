// lib/features/notifications/data/local_notifications_builder.dart
//
// Offline notification source. The inbox proper is server-backed
// (`GET /api/notifications`), so when the backend is undeployed / slow /
// unreachable the bell opens to an empty or error screen even though the
// user has upcoming shoots on their own device. This builder derives
// notifications from the local booking list so the inbox is always
// useful offline — mirroring the local-first pattern used for search.
//
// Pure Dart — no Riverpod, network, or platform imports — so the mapping
// is exhaustively unit-testable. The controller feeds it the already
// role-scoped booking list.

import '../../../core/booking_status/booking_status.dart';
import '../../bookings/domain/booking.dart';
import '../domain/app_notification.dart';

class LocalNotificationsBuilder {
  const LocalNotificationsBuilder._();

  /// Prefix that marks a notification as locally derived. Used to keep
  /// these ids stable across refreshes and to dedupe against any server
  /// row that points at the same booking.
  static const String idPrefix = 'local-booking-';

  /// How far ahead a booking counts as "upcoming" for the inbox.
  static const int horizonDays = 7;

  /// Builds inbox notifications for every upcoming, non-terminal booking
  /// within [horizonDays]. [now] is injectable for testing.
  static List<AppNotification> fromBookings(
    Iterable<Booking> bookings, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final horizon = today.add(const Duration(days: horizonDays + 1));

    final upcoming =
        bookings
            .where(
              (b) =>
                  b.status != BookingStatus.cancelled &&
                  b.status != BookingStatus.completed &&
                  !b.date.isBefore(today) &&
                  b.date.isBefore(horizon),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming
        .map((b) => _toNotification(b, today))
        .toList(growable: false);
  }

  static AppNotification _toNotification(Booking b, DateTime today) {
    final name = b.clientName?.trim().isNotEmpty == true
        ? b.clientName!.trim()
        : b.title;
    final when = _relativeDay(b.date, today);
    final venue = (b.venue?.trim().isNotEmpty ?? false)
        ? ' at ${b.venue!.trim()}'
        : '';

    return AppNotification(
      id: '$idPrefix${b.id}',
      category: 'OPERATIONS',
      message: 'Upcoming shoot: $name $when (${b.startTime})$venue',
      // Local reminders are informational — never rendered as "unread" so
      // they don't inflate the bell's unread badge with routine items.
      read: true,
      sentAt: DateTime(b.date.year, b.date.month, b.date.day),
      deeplink: '/bookings/${b.id}',
    );
  }

  static String _relativeDay(DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff <= 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return 'in $diff days';
  }
}
