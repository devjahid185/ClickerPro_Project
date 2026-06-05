// lib/features/payments/data/payment_api.dart
//
// Wire-level methods for the payment tracking endpoints.
// Stub implementation — endpoints to be wired when the backend lands.

import '../../../core/network/api_client.dart';
import '../domain/payment_record.dart';

class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  Future<List<PaymentRecord>> list() async {
    final r = await _client.get('/api/payments') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(PaymentRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<PaymentRecord>> listByEvent(String eventId) async {
    final r =
        await _client.get('/api/payments', query: {'eventId': eventId})
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(PaymentRecord.fromJson)
        .toList(growable: false);
  }

  Future<PaymentRecord> create(PaymentRecord draft) async {
    final r =
        await _client.post('/api/payments', body: draft.toCreateJson())
            as Map<String, dynamic>;
    final created = (r['payment'] as Map).cast<String, dynamic>();
    return PaymentRecord.fromJson(created);
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/payments/$id');
  }
}
