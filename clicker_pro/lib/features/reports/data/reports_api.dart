// lib/features/reports/data/reports_api.dart
//
// Reports endpoints against the Laravel backend.
//
// Laravel contract:
//   GET /api/reports/yearly-summary?year=YYYY
//       → { data: { year, summary: {totalRevenue, totalExpenses,
//                   totalFreelancerPayouts, netProfit} } }
//   GET /api/reports/team-performance?year=YYYY (year omitted = all-time)
//       → { data: { teamPerformance: [entry…] } }
//
// (Both endpoints ship with the Phase-1 backend batch; the `{data}`
// envelope is unwrapped here, tolerating flat legacy responses.)

import '../../../core/network/api_client.dart';
import '../domain/team_performance_entry.dart';
import '../domain/yearly_summary.dart';

class ReportsApi {
  ReportsApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _data(dynamic r) {
    if (r is! Map) return <String, dynamic>{};
    final d = r['data'];
    return (d is Map ? d : r).cast<String, dynamic>();
  }

  Future<YearlySummary> yearlySummary(int year) async {
    final r = await _client.get(
      '/api/reports/yearly-summary',
      query: {'year': year.toString()},
    );
    return YearlySummary.fromJson(_data(r));
  }

  Future<List<TeamPerformanceEntry>> teamPerformance(int year) async {
    final r = await _client.get(
      '/api/reports/team-performance',
      query: year == 0 ? null : {'year': year.toString()},
    );
    final raw = _data(r)['teamPerformance'] ?? const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => TeamPerformanceEntry.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
