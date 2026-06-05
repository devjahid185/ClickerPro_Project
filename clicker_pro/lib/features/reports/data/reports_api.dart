// lib/features/reports/data/reports_api.dart
//
// Wire-level methods for the reports endpoints।
//
//   GET /api/reports/yearly-summary?year=YYYY
//   GET /api/reports/team-performance?year=YYYY  (year omitted for All-Time)
//
// Both endpoints require `Authorization: Bearer <jwt>` (auto-applied by
// `ApiClient`)।

import '../../../core/network/api_client.dart';
import '../domain/team_performance_entry.dart';
import '../domain/yearly_summary.dart';

class ReportsApi {
  ReportsApi(this._client);

  final ApiClient _client;

  Future<YearlySummary> yearlySummary(int year) async {
    final r =
        await _client.get(
              '/api/reports/yearly-summary',
              query: {'year': year.toString()},
            )
            as Map<String, dynamic>;
    return YearlySummary.fromJson(r);
  }

  Future<List<TeamPerformanceEntry>> teamPerformance(int year) async {
    final r =
        await _client.get(
              '/api/reports/team-performance',
              query: year == 0 ? null : {'year': year.toString()},
            )
            as Map<String, dynamic>;
    final raw = (r['teamPerformance'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(TeamPerformanceEntry.fromJson)
        .toList(growable: false);
  }
}
