// lib/features/payments/domain/payment_repository.dart
//
// Abstract contract for the payment tracking feature. Implementation
// lives in `data/payment_repository_impl.dart`.

import 'payment_record.dart';

abstract class PaymentRepository {
  Future<List<PaymentRecord>> list();

  Future<List<PaymentRecord>> listByEvent(String eventId);

  Future<PaymentRecord> create(PaymentRecord draft);

  Future<void> delete(String id);
}
