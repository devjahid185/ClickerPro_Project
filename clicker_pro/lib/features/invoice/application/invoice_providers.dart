// lib/features/invoice/application/invoice_providers.dart
//
// Riverpod wiring for the invoice feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/invoice_api.dart';
import '../data/invoice_repository_impl.dart';
import '../domain/invoice.dart';
import '../domain/invoice_repository.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final invoiceApiProvider = Provider<InvoiceApi>(
  (ref) => InvoiceApi(ref.read(apiClientProvider)),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepositoryImpl(api: ref.read(invoiceApiProvider)),
);

// ─── 2. List controller ───────────────────────────────────────────────

class InvoiceListController extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    return ref.read(invoiceRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(invoiceRepositoryProvider).list(),
    );
  }

  Future<Invoice> add(Invoice draft) async {
    final saved = await ref.read(invoiceRepositoryProvider).create(draft);
    state.whenData((current) {
      state = AsyncData(<Invoice>[saved, ...current]);
    });
    return saved;
  }

  Future<Invoice> markSent(String id) async {
    await ref.read(invoiceRepositoryProvider).markSent(id);
    state.whenData((current) {
      state = AsyncData([
        for (final inv in current)
          if (inv.id == id)
            inv.copyWith(status: 'sent', sentAt: DateTime.now())
          else
            inv,
      ]);
    });
    return ref.read(invoiceRepositoryProvider).getById(id);
  }
}

final invoiceListControllerProvider =
    AsyncNotifierProvider<InvoiceListController, List<Invoice>>(
      InvoiceListController.new,
    );
