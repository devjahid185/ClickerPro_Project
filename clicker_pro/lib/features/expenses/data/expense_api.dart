// lib/features/expenses/data/expense_api.dart
//
// Wire-level methods for the expense endpoints.  Mirrors the backend
// routes in `backend/src/routes/expenseRoutes.js`:
//
//   POST /api/expenses        → create
//   GET  /api/expenses        → list (owner-scoped, desc by date)
//   GET  /api/expenses/profit → income/expense/net snapshot
//
// All three endpoints require the `Bearer <jwt>` header — supplied by
// `ApiClient` automatically.

import '../../../core/network/api_client.dart';
import '../domain/expense.dart';
import '../domain/profit_loss.dart';

class ExpenseApi {
  ExpenseApi(this._client);

  final ApiClient _client;

  /// `GET /api/expenses` — returns the owner's expense list, newest
  /// first.  Backend response shape:
  ///   { success: true, count: N, data: [Expense, ...] }
  Future<List<Expense>> list() async {
    final r = await _client.get('/api/expenses') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(Expense.fromJson)
        .toList(growable: false);
  }

  /// `POST /api/expenses` — body is the create payload from
  /// `Expense.toCreateJson()`.  Backend response:
  ///   { success: true, message, expense: { ... } }
  Future<Expense> create(Expense draft) async {
    final r =
        await _client.post('/api/expenses', body: draft.toCreateJson())
            as Map<String, dynamic>;
    final created = (r['expense'] as Map).cast<String, dynamic>();
    return Expense.fromJson(created);
  }

  /// `GET /api/expenses/profit` — owner-scoped income/expense aggregate.
  Future<ProfitLoss> profit() async {
    final r = await _client.get('/api/expenses/profit') as Map<String, dynamic>;
    return ProfitLoss.fromJson(r);
  }
}
