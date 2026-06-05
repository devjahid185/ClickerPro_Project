// lib/features/invoice/data/invoice_api.dart
//
// Wire-level methods for the invoice endpoints.
// Stub implementation — endpoints to be wired when the backend lands.

import '../../../core/network/api_client.dart';
import '../domain/invoice.dart';

class InvoiceApi {
  InvoiceApi(this._client);

  final ApiClient _client;

  Future<List<Invoice>> list() async {
    final r = await _client.get('/api/invoices') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList(growable: false);
  }

  Future<Invoice> getById(String id) async {
    final r = await _client.get('/api/invoices/$id') as Map<String, dynamic>;
    return Invoice.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  Future<Invoice> create(Invoice draft) async {
    final r =
        await _client.post('/api/invoices', body: draft.toCreateJson())
            as Map<String, dynamic>;
    final created = (r['invoice'] as Map).cast<String, dynamic>();
    return Invoice.fromJson(created);
  }

  Future<Invoice> update(String id, Map<String, dynamic> fields) async {
    final r =
        await _client.patch('/api/invoices/$id', body: fields)
            as Map<String, dynamic>;
    final updated = (r['invoice'] as Map).cast<String, dynamic>();
    return Invoice.fromJson(updated);
  }

  Future<void> markSent(String id) async {
    await _client.patch('/api/invoices/$id/send', body: const {});
  }
}
