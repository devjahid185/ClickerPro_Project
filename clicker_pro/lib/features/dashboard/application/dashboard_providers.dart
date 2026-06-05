// lib/features/dashboard/application/dashboard_providers.dart
//
// Dashboard data layer — Foundation slice.
//
// Phase 2 will plug a real source (Drift + remote stats). For this slice we
// emit a single placeholder so the UI demonstrates the AsyncValue.when()
// shape (loading → LensLoader, error → ErrorState with retry, data → tiles).

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    todayEvents: 8,
    upcomingEvents: 24,
    successEvents: 128,
    totalEvents: 142,
    todayCollection: 4250000, // ৳42,500.00
    pendingDue: 18450000, // ৳1,84,500.00
    holidaysThisMonth: 2,
    cancelledEvents: 7,
  );
}

/// Streams the typed metrics tile data. The brief delay lets the LensLoader
/// state visibly render on first paint instead of flash-skipping.
final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) async* {
  await Future<void>.delayed(const Duration(milliseconds: 220));
  yield DashboardMetrics.placeholder;
});

/// Selected weekday-strip cell. Defaults to today (date-normalized so the
/// strip's "isSameDay" check is stable across rebuilds).
final dashboardSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
