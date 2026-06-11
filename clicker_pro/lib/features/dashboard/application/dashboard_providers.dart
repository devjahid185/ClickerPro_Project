// lib/features/dashboard/application/dashboard_providers.dart
//
// Dashboard data layer — derives live metrics from the local Drift DB
// via bookingListProvider so numbers update whenever bookings change.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/booking_status/booking_status.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking_filter.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.todayEvents,
    required this.upcomingEvents,
    required this.successEvents,
    required this.totalEvents,
    required this.todayCollection,
    required this.pendingDue,
    required this.holidaysThisMonth,
    required this.cancelledEvents,
  });

  final int todayEvents;
  final int upcomingEvents;
  final int successEvents;
  final int totalEvents;
  final int todayCollection; // minor units (paisa)
  final int pendingDue; // minor units (paisa)
  final int holidaysThisMonth;
  final int cancelledEvents;

  static const placeholder = DashboardMetrics(
    todayEvents: 0,
    upcomingEvents: 0,
    successEvents: 0,
    totalEvents: 0,
    todayCollection: 0,
    pendingDue: 0,
    holidaysThisMonth: 0,
    cancelledEvents: 0,
  );
}

/// Derives dashboard metrics from the live booking stream.
final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) {
  final bookingsAsync = ref.watch(bookingListProvider(const BookingFilter()));
  return bookingsAsync.when(
    loading: () => Stream.value(DashboardMetrics.placeholder),
    error: (_, _) => Stream.value(DashboardMetrics.placeholder),
    data: (bookings) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int todayEvents = 0;
      int upcomingEvents = 0;
      int successEvents = 0;
      int cancelledEvents = 0;
      int pendingDueCount = 0; // count of pending-payment bookings
      int todayRevenue = 0; // sum of customPrice for today bookings in paisa

      for (final b in bookings) {
        final bDate = DateTime(b.date.year, b.date.month, b.date.day);
        if (bDate == today) {
          todayEvents++;
          final price = b.customPrice ?? 0;
          todayRevenue += (price * 100).round();
        }
        if (bDate.isAfter(today) &&
            b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.completed) {
          upcomingEvents++;
        }
        if (b.status == BookingStatus.completed ||
            b.status == BookingStatus.delivered) {
          successEvents++;
        }
        if (b.status == BookingStatus.cancelled) cancelledEvents++;
        if (b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.inProgress) {
          pendingDueCount++;
        }
      }

      // pendingDue expressed in paisa as a rough estimate
      final avgPrice = bookings.isEmpty
          ? 0
          : bookings
                  .map((b) => ((b.customPrice ?? 0) * 100).round())
                  .fold<int>(0, (a, b) => a + b) ~/
              bookings.length;

      return Stream.value(
        DashboardMetrics(
          todayEvents: todayEvents,
          upcomingEvents: upcomingEvents,
          successEvents: successEvents,
          totalEvents: bookings.length,
          todayCollection: todayRevenue,
          pendingDue: pendingDueCount * avgPrice,
          holidaysThisMonth: bdHolidaysInMonth(DateTime.now()),
          cancelledEvents: cancelledEvents,
        ),
      );
    },
  );
});

/// Selected weekday-strip cell. Defaults to today (date-normalized so the
/// strip's "isSameDay" check is stable across rebuilds).
final dashboardSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// One booking with money still owed — feeds the dashboard's Due
/// drill-down sheet ("which events have dues").
class DueEntry {
  const DueEntry({
    required this.bookingId,
    required this.title,
    required this.clientName,
    required this.date,
    required this.total,
    required this.paid,
  });

  final String bookingId;
  final String title;
  final String? clientName;
  final DateTime date;
  final double total;
  final double paid;

  double get due => total - paid;
}

/// Per-event due breakdown: every non-cancelled booking with a price
/// whose payments don't cover the total yet, newest event first.
final dueBreakdownProvider = FutureProvider<List<DueEntry>>((ref) async {
  final bookings = await ref.watch(
    bookingListProvider(const BookingFilter()).future,
  );
  final payRepo = ref.read(paymentRepositoryProvider);

  final entries = <DueEntry>[];
  for (final b in bookings) {
    if (b.status == BookingStatus.cancelled) continue;
    final total = b.customPrice;
    if (total == null || total <= 0) continue;
    final agg = await payRepo.aggregateForBooking(b.id);
    final due = total - agg.total;
    if (due <= 0.5) continue;
    entries.add(
      DueEntry(
        bookingId: b.id,
        title: b.title,
        clientName: b.clientName,
        date: b.date,
        total: total,
        paid: agg.total,
      ),
    );
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});
