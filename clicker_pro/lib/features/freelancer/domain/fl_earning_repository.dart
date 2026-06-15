// lib/features/freelancer/domain/fl_earning_repository.dart
//
// Abstract contract for the freelancer earnings feature.
// Implementation lives in `data/fl_earning_repository_impl.dart`.

import 'fl_earning.dart';

abstract class FlEarningRepository {
  /// Full earnings overview — current month totals, per-owner breakdown,
  /// pending payments, and yearly recap.
  Future<FlEarningsOverview> overview();

  /// Request payment from all owners with pending balances.
  Future<bool> requestPayment({
    double? amount,
    String? bkash,
    String? bankDetails,
    String? note,
  });
}
