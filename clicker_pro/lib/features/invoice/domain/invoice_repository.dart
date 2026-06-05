// lib/features/invoice/domain/invoice_repository.dart
//
// Abstract contract for the invoice feature. Implementation lives in
// `data/invoice_repository_impl.dart`.

import 'invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> list();

  Future<Invoice> getById(String id);

  Future<Invoice> create(Invoice draft);

  Future<Invoice> update(String id, Map<String, dynamic> fields);

  Future<void> markSent(String id);
}
