// lib/features/expenses/application/expense_providers.dart
//
// Riverpod wiring for the expense feature।  Three layers:
//
//   1. API + Repository providers — thin construction over `apiClientProvider`।
//   2. List controller             — `AsyncNotifier` that holds the live list।
//   3. Profit-loss provider        — `FutureProvider`, refreshes on demand
//      after a successful create।

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/expense_api.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';
import '../domain/profit_loss.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final expenseApiProvider = Provider<ExpenseApi>(
  (ref) => ExpenseApi(ref.read(apiClientProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepositoryImpl(
    api: ref.read(expenseApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

// ─── 2. List controller ───────────────────────────────────────────────

/// `AsyncNotifier` that owns the expense list state.  `build()` does the
/// initial fetch; `refresh()` re-fetches; `add()` posts a new expense
/// and prepends it to the cached list (no full re-fetch needed)।
class ExpenseListController extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(expenseRepositoryProvider).list();
  }

  /// Pull-to-refresh / FAB pulldown handler.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).list(),
    );
  }

  /// Records a new expense and updates the cached list optimistically।
  /// On error the cached list stays put and the caller surfaces a
  /// SnackBar — we rethrow so the dialog can decide whether to close।
  Future<Expense> add(Expense draft) async {
    final saved = await ref.read(expenseRepositoryProvider).create(draft);
    state.whenData((current) {
      // Prepend — backend list is descending date order.
      state = AsyncData(<Expense>[saved, ...current]);
    });
    // Profit-loss tile depends on the totals — invalidate so it refetches.
    ref.invalidate(profitLossProvider);
    return saved;
  }
}

final expenseListControllerProvider =
    AsyncNotifierProvider<ExpenseListController, List<Expense>>(
      ExpenseListController.new,
    );

// ─── 3. Profit / Loss snapshot ────────────────────────────────────────

final profitLossProvider = FutureProvider<ProfitLoss>(
  (ref) => ref.read(expenseRepositoryProvider).profitLoss(),
);
