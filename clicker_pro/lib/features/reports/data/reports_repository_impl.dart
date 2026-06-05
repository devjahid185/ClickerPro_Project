// lib/features/reports/data/reports_repository_impl.dart
//
// Online-first repo — no local cache.  Reports are derived numbers; if
// we miss the network, the UI surfaces the error inline and offers
// retry।

import '../domain/reports_repository.dart';
import '../domain/team_performance_entry.dart';
import '../domain/yearly_summary.dart';
import 'reports_api.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required ReportsApi api}) : _api = api;

  final ReportsApi _api;

  @override
  Future<YearlySummary> yearlySummary(int year) => _api.yearlySummary(year);

  @override
  Future<List<TeamPerformanceEntry>> teamPerformance(int year) =>
      _api.teamPerformance(year);
}
