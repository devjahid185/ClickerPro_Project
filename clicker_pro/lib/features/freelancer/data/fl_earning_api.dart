// lib/features/freelancer/data/fl_earning_api.dart
//
// Wire-level methods for the freelancer earnings endpoints.
// Backend routes expected:
//
//   GET /api/freelancer/earnings          → overview snapshot
//   GET /api/freelancer/earnings/monthly  → 6-month bar chart data
//   POST /api/freelancer/earnings/request-payment → request payout
//
// All endpoints require the `Bearer <jwt>` header — supplied by
// `ApiClient` automatically.

import '../../../core/network/api_client.dart';
import '../domain/fl_earning.dart';

class FlEarningApi {
  FlEarningApi(this._client);

  final ApiClient _client;

  /// `GET /api/freelancer/earnings` — full overview snapshot.
  /// Backend response shape:
  ///   { success: true, data: { totalEarnings, receivedAmount,
  ///     pendingAmount, owners, pendingPayments, yearlyRecap } }
  Future<FlEarningsOverview> overview() async {
    final r =
        await _client.get('/api/freelancer/earnings') as Map<String, dynamic>;
    final data = (r['data'] as Map<String, dynamic>?) ?? r;
    return FlEarningsOverview.fromJson(data);
  }

  /// `POST /api/freelancer/earnings/request-payment` — app-to-app due
  /// payment request to the owner, carrying the freelancer's bKash /
  /// bank details so the owner can pay without asking. Returns `true`
  /// on success.
  Future<bool> requestPayment({
    double? amount,
    String? bkash,
    String? bankDetails,
    String? note,
  }) async {
    final r =
        await _client.post(
              '/api/freelancer/earnings/request-payment',
              body: <String, dynamic>{
                if (amount != null && amount > 0) 'amount': amount,
                if (bkash != null && bkash.isNotEmpty) 'bkash': bkash,
                if (bankDetails != null && bankDetails.isNotEmpty)
                  'bankDetails': bankDetails,
                if (note != null && note.isNotEmpty) 'note': note,
              },
            )
            as Map<String, dynamic>;
    return r['success'] == true;
  }
}
