// lib/features/expenses/domain/expense_repository.dart
//
// Abstract contract for the expense feature.  Implementation lives in
// `data/expense_repository_impl.dart` — online-first for this MVP slice;
// a Drift cache + outbox extension comes in a follow-up slice once the
// `expenses_table` migration lands in the schema bump.

import 'expense.dart';
import 'profit_loss.dart';

abstract class ExpenseRepository {
  /// `GET /api/expenses` — owner-scoped descending date list.  Returns a
  /// fresh fetch every call; UI tier handles caching via Riverpod
  /// `AsyncNotifier`.
  Future<List<Expense>> list();

  /// `POST /api/expenses` — record a new expense.  Backend coerces the
  /// `amount` field via `parseFloat`, so we don't need to round-trip a
  /// string here.
  Future<Expense> create(Expense draft);

  /// `GET /api/expenses/profit` — income / expense / net snapshot for
  /// the dashboard tile and the per-screen header.
  Future<ProfitLoss> profitLoss();
}
