// lib/features/expenses/data/expense_api.dart
//
// Wire-level methods for the expense endpoints. Mirrors the Laravel routes
// in `laravel_backend/routes/api.php`:
//
//   POST   /api/expenses       → store  (ExpenseController@store)
//   GET    /api/expenses       → index  (owner-scoped, desc by date)
//   PATCH  /api/expenses/{id}  → update
//   DELETE /api/expenses/{id}  → destroy
//
// Laravel wraps every payload in a `{ "data": ... }` envelope, uses
// snake_case columns and integer ids. The translation lives in
// `Expense.fromJson` / `toCreateJson`; here we just unwrap the envelope.
//
// NOTE: there is no `/expenses/profit` endpoint on the Laravel backend —
// the profit/loss card is computed from the local cache in the repository.
//
// All endpoints require the `Bearer <jwt>` header — supplied by
// `ApiClient` automatically.

import '../../bookings/data/server_wire.dart'
    show unwrapServerList, unwrapServerMap;
import '../../../core/network/api_client.dart';
import '../domain/expense.dart';

class ExpenseApi {
  ExpenseApi(this._client);

  final ApiClient _client;

  /// `GET /api/expenses` — returns the owner's expense list, newest first.
  /// Response shape: `{ "data": [ { ... }, ... ] }`.
  Future<List<Expense>> list() async {
    final r = await _client.get('/api/expenses');
    return unwrapServerList(r)
        .map(Expense.fromJson)
        .toList(growable: false);
  }

  /// `POST /api/expenses` — body is the create payload from
  /// `Expense.toCreateJson()`. Laravel responds `201` with the created
  /// row wrapped as `{ "data": { ... } }`.
  Future<Expense> create(Expense draft) async {
    final r = await _client.post('/api/expenses', body: draft.toCreateJson());
    return Expense.fromJson(unwrapServerMap(r));
  }
}
