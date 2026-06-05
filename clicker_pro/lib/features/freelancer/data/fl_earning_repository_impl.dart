// lib/features/freelancer/data/fl_earning_repository_impl.dart
//
// Online-first repo — no Drift cache.  Any network/auth error bubbles
// up as ApiException; the UI tier catches and surfaces in SnackBar /
// inline error state.

import '../domain/fl_earning.dart';
import '../domain/fl_earning_repository.dart';
import 'fl_earning_api.dart';

class FlEarningRepositoryImpl implements FlEarningRepository {
  FlEarningRepositoryImpl({required FlEarningApi api}) : _api = api;

  final FlEarningApi _api;

  @override
  Future<FlEarningsOverview> overview() => _api.overview();

  @override
  Future<bool> requestPayment() => _api.requestPayment();
}
