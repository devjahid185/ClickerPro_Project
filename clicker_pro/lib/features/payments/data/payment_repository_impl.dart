// lib/features/payments/data/payment_repository_impl.dart
//
// Online-first repository — no Drift cache for the MVP slice. Reads tolerate
// being offline: a transport-level failure (no connectivity) yields an empty
// list rather than throwing, so the screen shows its empty state instead of
// the red "Failed to load payments" error. Genuine server errors (4xx/5xx)
// still propagate so real backend problems stay visible.

import '../../../core/network/api_exception.dart';
import '../domain/payment_record.dart';
import '../domain/payment_repository.dart';
import 'payment_api.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required PaymentApi api}) : _api = api;

  final PaymentApi _api;

  @override
  Future<List<PaymentRecord>> list() async {
    try {
      return await _api.list();
    } on ApiException catch (e) {
      if (e.isNetwork) return const <PaymentRecord>[];
      rethrow;
    }
  }

  @override
  Future<List<PaymentRecord>> listByEvent(String eventId) async {
    try {
      return await _api.listByEvent(eventId);
    } on ApiException catch (e) {
      if (e.isNetwork) return const <PaymentRecord>[];
      rethrow;
    }
  }

  @override
  Future<PaymentRecord> create(PaymentRecord draft) => _api.create(draft);

  @override
  Future<void> delete(String id) => _api.delete(id);
}
