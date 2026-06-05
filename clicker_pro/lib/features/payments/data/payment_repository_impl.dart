// lib/features/payments/data/payment_repository_impl.dart
//
// Online-first repository — no Drift cache for the MVP slice.

import '../domain/payment_record.dart';
import '../domain/payment_repository.dart';
import 'payment_api.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required PaymentApi api}) : _api = api;

  final PaymentApi _api;

  @override
  Future<List<PaymentRecord>> list() => _api.list();

  @override
  Future<List<PaymentRecord>> listByEvent(String eventId) =>
      _api.listByEvent(eventId);

  @override
  Future<PaymentRecord> create(PaymentRecord draft) => _api.create(draft);

  @override
  Future<void> delete(String id) => _api.delete(id);
}
