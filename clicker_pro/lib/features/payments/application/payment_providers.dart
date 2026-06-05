// lib/features/payments/application/payment_providers.dart
//
// Riverpod wiring for the payment tracking feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/payment_api.dart';
import '../data/payment_repository_impl.dart';
import '../domain/payment_record.dart';
import '../domain/payment_repository.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final paymentApiProvider = Provider<PaymentApi>(
  (ref) => PaymentApi(ref.read(apiClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(api: ref.read(paymentApiProvider)),
);

// ─── 2. List controller ───────────────────────────────────────────────

class PaymentListController extends AsyncNotifier<List<PaymentRecord>> {
  @override
  Future<List<PaymentRecord>> build() async {
    return ref.read(paymentRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(paymentRepositoryProvider).list(),
    );
  }

  Future<PaymentRecord> add(PaymentRecord draft) async {
    final saved = await ref.read(paymentRepositoryProvider).create(draft);
    state.whenData((current) {
      state = AsyncData(<PaymentRecord>[saved, ...current]);
    });
    return saved;
  }
}

final paymentListControllerProvider =
    AsyncNotifierProvider<PaymentListController, List<PaymentRecord>>(
      PaymentListController.new,
    );

// ─── 3. Per-event payments ────────────────────────────────────────────

final eventPaymentsProvider =
    FutureProvider.family<List<PaymentRecord>, String>((ref, eventId) async {
      return ref.read(paymentRepositoryProvider).listByEvent(eventId);
    });
