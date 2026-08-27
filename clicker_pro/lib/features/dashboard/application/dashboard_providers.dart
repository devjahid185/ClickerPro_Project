// lib/features/dashboard/application/dashboard_providers.dart
//
// Dashboard data layer — derives live metrics from the local Drift DB
// via bookingListProvider so numbers update whenever bookings change.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/booking_status/booking_status.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../bookings/domain/package.dart' as booking_pkg;
import '../../bookings/domain/shift.dart';

Map<String, booking_pkg.Package> _packageLookup(
  List<booking_pkg.Package> packages,
) {
  return <String, booking_pkg.Package>{
    for (final p in packages) p.id: p,
    for (final p in packages)
      if (p.remoteId != null) p.remoteId!: p,
  };
}

double _bookingTotal(
  Booking booking,
  Map<String, booking_pkg.Package> packageById,
) {
  final custom = booking.customPrice;
  if (custom != null && custom > 0) return custom;
  final packageId = booking.packageId;
  if (packageId == null || packageId.isEmpty) return 0;
  final package = packageById[packageId];
  return package == null ? 0 : package.netPrice;
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.todayEvents,
    required this.todayDayEvents,
    required this.todayNightEvents,
    required this.upcomingEvents,
    required this.successEvents,
    required this.totalEvents,
    required this.todayCollection,
    required this.pendingDue,
    required this.holidaysThisMonth,
    required this.cancelledEvents,
  });

  final int todayEvents;
  final int todayDayEvents; // today's events on the Day shift
  final int todayNightEvents; // today's events on the Night shift
  final int upcomingEvents;
  final int successEvents;
  final int totalEvents;
  final int todayCollection; // minor units (paisa)
  final int pendingDue; // minor units (paisa)
  final int holidaysThisMonth;
  final int cancelledEvents;

  static const placeholder = DashboardMetrics(
    todayEvents: 0,
    todayDayEvents: 0,
    todayNightEvents: 0,
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
  final bookingsAsync = ref.watch(bookingListAllProvider(const BookingFilter()));
  return bookingsAsync.when(
    loading: () => Stream.value(DashboardMetrics.placeholder),
    error: (_, _) => Stream.value(DashboardMetrics.placeholder),
    data: (bookings) {
      final packages = ref.watch(packagesProvider).valueOrNull ??
          const <booking_pkg.Package>[];
      final packageById = _packageLookup(packages);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int todayEvents = 0;
      int todayDayEvents = 0;
      int todayNightEvents = 0;
      int upcomingEvents = 0;
      int successEvents = 0;
      int cancelledEvents = 0;
      int todayRevenue = 0; // sum of customPrice for today bookings in paisa

      for (final b in bookings) {
        final bDate = DateTime(b.date.year, b.date.month, b.date.day);
        // "Today" = events whose calendar date is today. A night shift
        // (6pm–11pm) still belongs to the same calendar day, so a simple
        // date match is correct — no time-of-day rollover.
        if (bDate == today && b.status != BookingStatus.cancelled) {
          todayEvents++;
          // Real day/night split (was a fake 60/40 placeholder before).
          // A "both" shift counts toward both buckets.
          if (b.shift == Shift.night) {
            todayNightEvents++;
          } else if (b.shift == Shift.day) {
            todayDayEvents++;
          } else {
            todayDayEvents++;
            todayNightEvents++;
          }
          final price = _bookingTotal(b, packageById);
          todayRevenue += (price * 100).round();
        }
        // "Upcoming" = every future event that is NOT yet finished, however
        // far ahead ("১ দিন হোক বা ১০ বছর"). Finished = delivered/completed;
        // cancelled events never count. No upper date bound.
        if (bDate.isAfter(today) &&
            b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.completed &&
            b.status != BookingStatus.delivered) {
          upcomingEvents++;
        }
        // "Complete" card = every event whose shoot has happened
        // (shotComplete and beyond), per Heaven feedback 2026-07.
        if (b.status == BookingStatus.completed ||
            b.status == BookingStatus.delivered ||
            b.status == BookingStatus.shotComplete) {
          successEvents++;
        }
        if (b.status == BookingStatus.cancelled) cancelledEvents++;
      }

      // Real outstanding due = Σ(total − payments) across non-cancelled
      // bookings, sourced from `dueBreakdownProvider` (which aggregates
      // actual payments per event). The previous `count × avgPrice` estimate
      // produced a meaningless figure — and ৳0 whenever bookings had no
      // customPrice — which is the "due count হয় না" bug.
      return ref.watch(dueBreakdownProvider.future).then((dueEntries) {
        final pendingDuePaisa = dueEntries.fold<int>(
          0,
          (sum, e) => sum + (e.due * 100).round(),
        );
        return DashboardMetrics(
          todayEvents: todayEvents,
          todayDayEvents: todayDayEvents,
          todayNightEvents: todayNightEvents,
          upcomingEvents: upcomingEvents,
          successEvents: successEvents,
          totalEvents: bookings.length,
          todayCollection: todayRevenue,
          pendingDue: pendingDuePaisa,
          holidaysThisMonth: bdHolidaysInMonth(DateTime.now()),
          cancelledEvents: cancelledEvents,
        );
      }).asStream();
    },
  );
});

/// Selected weekday-strip cell. Defaults to today (date-normalized so the
/// strip's "isSameDay" check is stable across rebuilds).
final dashboardSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Non-cancelled event counts for the current Mon→Sun week, indexed 0 (Mon)
/// through 6 (Sun). Feeds the weekday strip's "has event" dots so they reflect
/// real bookings instead of a hardcoded pattern.
final weekEventCountsProvider = Provider<List<int>>((ref) {
  final bookings = ref
      .watch(bookingListAllProvider(const BookingFilter()))
      .valueOrNull;
  final counts = List<int>.filled(7, 0);
  if (bookings == null) return counts;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));

  for (final b in bookings) {
    if (b.status == BookingStatus.cancelled) continue;
    final bDate = DateTime(b.date.year, b.date.month, b.date.day);
    if (bDate.isBefore(monday) || bDate.isAfter(sunday)) continue;
    counts[bDate.weekday - 1]++;
  }
  return counts;
});

/// Count of shot/delivered/completed events whose date falls in the current
/// calendar month. Feeds the Complete strip's "+N this month" caption.
final deliveredThisMonthProvider = Provider<int>((ref) {
  final bookings = ref
      .watch(bookingListAllProvider(const BookingFilter()))
      .valueOrNull;
  if (bookings == null) return 0;

  final now = DateTime.now();
  var count = 0;
  for (final b in bookings) {
    if (b.status != BookingStatus.completed &&
        b.status != BookingStatus.delivered &&
        b.status != BookingStatus.shotComplete) {
      continue;
    }
    if (b.date.year == now.year && b.date.month == now.month) count++;
  }
  return count;
});

/// Delivered/completed counts per week for the last 4 weeks (oldest → newest),
/// bucketed by event date. Feeds the Delivered strip's mini bar chart so the
/// bars reflect a real recent trend rather than fixed decorative heights.
final deliveredTrendProvider = Provider<List<int>>((ref) {
  final bookings = ref
      .watch(bookingListAllProvider(const BookingFilter()))
      .valueOrNull;
  final buckets = List<int>.filled(4, 0);
  if (bookings == null) return buckets;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Bucket 3 = this week (last 7 days), bucket 0 = 4 weeks ago.
  final windowStart = today.subtract(const Duration(days: 27));

  for (final b in bookings) {
    if (b.status != BookingStatus.completed &&
        b.status != BookingStatus.delivered &&
        b.status != BookingStatus.shotComplete) {
      continue;
    }
    final bDate = DateTime(b.date.year, b.date.month, b.date.day);
    if (bDate.isBefore(windowStart) || bDate.isAfter(today)) continue;
    final daysAgo = today.difference(bDate).inDays; // 0..27
    final bucket = 3 - (daysAgo ~/ 7); // 0..3
    buckets[bucket]++;
  }
  return buckets;
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
    bookingListAllProvider(const BookingFilter()).future,
  );
  final packages = await ref.watch(packagesProvider.future);
  final packageById = _packageLookup(packages);
  final payRepo = ref.read(paymentRepositoryProvider);

  final entries = <DueEntry>[];
  for (final b in bookings) {
    if (b.status == BookingStatus.cancelled) continue;
    final total = _bookingTotal(b, packageById);
    if (total <= 0) continue;
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

/// Today's collected amounts grouped by payment method (cash/bkash/bank/…),
/// non-zero entries only, largest first. Feeds the "কোন খাত থেকে কালেকশন"
/// breakdown shown when the Today Collection card is tapped.
final todayCollectionByMethodProvider =
    FutureProvider<List<({String method, double amount})>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  final byMethod = await ref
      .read(paymentRepositoryProvider)
      .collectionByMethodBetween(start, end);
  final entries = byMethod.entries
      .where((e) => e.value > 0.005)
      .map((e) => (method: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return entries;
});
