// lib/features/reports/application/reports_providers.dart
//
// Riverpod wiring for the reports feature।  Three layers:
//
//   1. API + Repository providers — thin construction over `apiClientProvider`।
//   2. UI-state                    — `selectedYearProvider` (defaults to current year)।
//   3. Data providers              — `FutureProvider.family<int>` keyed
//      on the selected year so changing the dropdown invalidates+refetches।

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/reports_api.dart';
import '../data/reports_repository_impl.dart';
import '../domain/reports_repository.dart';
import '../domain/team_performance_entry.dart';
import '../domain/yearly_summary.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final reportsApiProvider = Provider<ReportsApi>(
  (ref) => ReportsApi(ref.read(apiClientProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(api: ref.read(reportsApiProvider)),
);

// ─── 2. UI state ──────────────────────────────────────────────────────

/// Selected year for the dashboard.  `0` represents "All Time" — the
/// team-performance endpoint accepts that as a magic value, the yearly
/// summary endpoint requires a real year so the UI hides the summary
/// card when 0 is selected।
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// ─── 3. Data providers (family-keyed on year) ────────────────────────

final yearlySummaryProvider = FutureProvider.family<YearlySummary, int>(
  (ref, year) => ref.read(reportsRepositoryProvider).yearlySummary(year),
);

final teamPerformanceProvider =
    FutureProvider.family<List<TeamPerformanceEntry>, int>(
      (ref, year) => ref.read(reportsRepositoryProvider).teamPerformance(year),
    );
