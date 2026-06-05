// lib/features/invoice/data/invoice_repository_impl.dart
//
// Online-first repository — no Drift cache for the MVP slice.

import '../domain/invoice.dart';
import '../domain/invoice_repository.dart';
import 'invoice_api.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl({required InvoiceApi api}) : _api = api;

  final InvoiceApi _api;

  @override
  Future<List<Invoice>> list() => _api.list();

  @override
  Future<Invoice> getById(String id) => _api.getById(id);

  @override
  Future<Invoice> create(Invoice draft) => _api.create(draft);

  @override
  Future<Invoice> update(String id, Map<String, dynamic> fields) =>
      _api.update(id, fields);

  @override
  Future<void> markSent(String id) => _api.markSent(id);
}
