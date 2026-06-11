// lib/features/bookings/data/payment_api.dart
//
// Wire-level methods for booking-scoped Payment endpoints against the
// Laravel backend. Shape translation lives in `server_wire.dart`.
//
// Laravel contract (routes/api.php + PaymentController):
//   POST   /api/payments                → { data: payment } (201)
//          body: { event_id, amount, kind, method?, note?, paid_at? }
//   GET    /api/payments/event/:eventId → { data: [payment…] }
//   PATCH  /api/payments/:id            → { data: payment }
//   DELETE /api/payments/:id            → { message: ok }

import '../../../core/network/api_client.dart';
import '../domain/payment.dart';
import 'server_wire.dart';

class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  /// Creates a payment against the booking's SERVER id. The response is
  /// mapped with the submitted payment as fallback so the LOCAL ids
  /// survive the round-trip.
  Future<Payment> create(String bookingRemoteId, Payment payment) async {
    final r = await _client.post(
      '/api/payments',
      body: paymentToServer(payment, eventRemoteId: bookingRemoteId),
    );
    return paymentFromServer(
      unwrapServerMap(r),
      bookingLocalId: payment.bookingId,
      fallback: payment,
    );
  }

  /// Lists a booking's payments. [bookingLocalId] is the local row the
  /// returned payments should reference.
  Future<List<Payment>> listByEvent(
    String bookingRemoteId, {
    required String bookingLocalId,
  }) async {
    final r = await _client.get('/api/payments/event/$bookingRemoteId');
    return unwrapServerList(r)
        .map((e) => paymentFromServer(e, bookingLocalId: bookingLocalId))
        .toList(growable: false);
  }

  /// Partial update. [partial] is the full local `Payment.toJson()` map
  /// (both call sites pass exactly that).
  Future<Payment> patch(
    String bookingRemoteId,
    String paymentRemoteId,
    Map<String, dynamic> partial,
  ) async {
    final local = Payment.fromJson(partial);
    final r = await _client.patch(
      '/api/payments/$paymentRemoteId',
      body: paymentToServer(local, eventRemoteId: bookingRemoteId),
    );
    return paymentFromServer(
      unwrapServerMap(r),
      bookingLocalId: local.bookingId,
      fallback: local,
    );
  }

  Future<void> delete(String bookingRemoteId, String paymentRemoteId) async {
    await _client.delete('/api/payments/$paymentRemoteId');
  }
}
