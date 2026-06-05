// lib/features/bookings/data/payment_api.dart
//
// Wire-level methods for booking-scoped Payment endpoints (CRUD per
// booking). Wraps `ApiClient` calls and returns plain `Payment`
// domain instances.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.10.

import '../../../core/network/api_client.dart';
import '../domain/payment.dart';

class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  /// `POST /api/bookings/:id/payments`.
  Future<Payment> create(String bookingRemoteId, Payment payment) async {
    final r =
        await _client.post(
              '/api/bookings/$bookingRemoteId/payments',
              body: payment.toJson(),
            )
            as Map<String, dynamic>;
    return Payment.fromJson((r['payment'] as Map).cast<String, dynamic>());
  }

  /// `PATCH /api/bookings/:id/payments/:paymentId`.
  Future<Payment> patch(
    String bookingRemoteId,
    String paymentRemoteId,
    Map<String, dynamic> partial,
  ) async {
    final r =
        await _client.patch(
              '/api/bookings/$bookingRemoteId/payments/$paymentRemoteId',
              body: partial,
            )
            as Map<String, dynamic>;
    return Payment.fromJson((r['payment'] as Map).cast<String, dynamic>());
  }

  /// `DELETE /api/bookings/:id/payments/:paymentId`.
  Future<void> delete(String bookingRemoteId, String paymentRemoteId) async {
    await _client.delete(
      '/api/bookings/$bookingRemoteId/payments/$paymentRemoteId',
    );
  }
}
