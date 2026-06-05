// lib/features/reports/domain/reports_repository.dart
//
// Reports feature contract — yearly summary + team performance roll-up।
// Online-first; no local cache (reports are derived numbers, fine to
// fetch on demand)।

import 'team_performance_entry.dart';
import 'yearly_summary.dart';

abstract class ReportsRepository {
  /// `GET /api/reports/yearly-summary?year=YYYY` — owner-scoped P&L
  /// snapshot.  Returns null only if the call fails; backend always
  /// returns 200 with zeros for empty studios।
  Future<YearlySummary> yearlySummary(int year);

  /// `GET /api/reports/team-performance?year=YYYY` — descending leaderboard।
  /// Pass `year = 0` for "All Time" (backend interprets a missing
  /// `?year=` param as all-time, so we send no query string for 0)।
  Future<List<TeamPerformanceEntry>> teamPerformance(int year);
}
