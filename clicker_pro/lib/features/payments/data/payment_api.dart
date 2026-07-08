// lib/features/payments/data/payment_api.dart
//
// Wire-level methods for the payment tracking endpoints. Fully wired to the
// Laravel routes in `laravel_backend/routes/api.php` (PaymentController):
// GET/POST /api/payments, GET /api/payments/event/{id}, DELETE /api/payments/{id}.
// A "Failed to load payments" in the app means the *deployed* server is behind
// the repo (route/migration not yet `git pull`ed + migrated on cPanel), not a
// missing client wiring.

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
    // Laravel exposes per-event payments at /api/payments/event/{id}.
    final r =
        await _client.get('/api/payments/event/$eventId')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(PaymentRecord.fromJson)
        .toList(growable: false);
  }

  Future<PaymentRecord> create(PaymentRecord draft) async {
    // Laravel wraps the created row in `data` (not `payment`); reading the
    // wrong key made every successful save look like a failure in the UI.
    final r =
        await _client.post('/api/payments', body: draft.toCreateJson())
            as Map<String, dynamic>;
    final created = ((r['data'] ?? r['payment']) as Map)
        .cast<String, dynamic>();
    return PaymentRecord.fromJson(created);
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/payments/$id');
  }
}
