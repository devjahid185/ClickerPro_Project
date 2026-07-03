import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/expenses_dao.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';
import '../domain/profit_loss.dart';
import 'expense_api.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({required ExpenseApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final ExpenseApi _api;
  final AppDatabase _db;

  ExpensesDao get _dao => _db.expensesDao;

  Expense _rowToExpense(ExpenseRow r) => Expense(
    id: r.remoteId ?? r.id,
    ownerId: r.ownerId,
    category: r.category,
    amount: r.amount,
    eventId: r.eventId,
    note: r.note,
    receiptUrl: r.receiptUrl,
    incurredAt: r.incurredAt,
    createdAt: r.createdAt,
  );

  ExpensesTableCompanion _modelToCompanion(Expense e, {bool pending = false}) {
    return ExpensesTableCompanion(
      id: Value(e.id),
      remoteId: Value(e.id),
      ownerId: Value(e.ownerId),
      category: Value(e.category),
      amount: Value(e.amount),
      eventId: Value(e.eventId),
      note: Value(e.note),
      receiptUrl: Value(e.receiptUrl),
      incurredAt: Value(e.incurredAt),
      createdAt: Value(e.createdAt),
      pending: Value(pending),
    );
  }

  @override
  Future<List<Expense>> list() async {
    try {
      final remote = await _api.list();
      // Locally-created expenses that haven't synced yet must survive the
      // refresh — otherwise an added expense vanishes on pull-to-refresh.
      final pending = await _dao.getPending();
      final rows = remote.map((e) => _modelToCompanion(e)).toList();
      // Only rewrite the synced cache when the server actually returned rows.
      // A successful-but-empty response (fresh session, transient backend
      // hiccup) must NOT wipe the local cache — that is exactly what made
      // added expenses "disappear" on refresh.
      if (rows.isNotEmpty) {
        await _dao.clearSynced();
        await _dao.upsertAll(rows);
      }
      // Show unsynced expenses first, then the server list. Drop any pending
      // row the server already knows about (id match) so a just-synced expense
      // doesn't appear twice.
      final remoteIds = remote.map((e) => e.id).toSet();
      final pendingModels = pending
          .map(_rowToExpense)
          .where((e) => !remoteIds.contains(e.id))
          .toList();
      return [...pendingModels, ...remote];
    } catch (_) {
      // Fallback to local cache if API is unreachable.
      final cached = await _dao.getAll();
      return cached.map(_rowToExpense).toList();
    }
  }

  @override
  Future<Expense> create(Expense draft) async {
    try {
      final saved = await _api.create(draft);
      // The server assigns a new id; drop the local draft row (if the caller
      // supplied a local id) so the synced row doesn't sit beside a stale
      // pending duplicate, then cache the authoritative server row.
      if (draft.id.isNotEmpty && draft.id != saved.id) {
        await _dao.deleteById(draft.id);
      }
      await _dao.upsert(_modelToCompanion(saved));
      return saved;
    } catch (_) {
      // If we can't reach the API, save locally as pending under the draft's
      // (unique, non-empty) local id so it survives a refresh and doesn't
      // collide with other offline drafts.
      await _dao.upsert(_modelToCompanion(draft, pending: true));
      return draft;
    }
  }

  @override
  Future<ProfitLoss> profitLoss() async {
    // The Laravel backend has no `/expenses/profit` endpoint, so the
    // expense-side total is computed from the local cache (which `list()`
    // keeps in sync with the server). Income is tracked by the payments
    // module elsewhere.
    final cached = await _dao.getAll();
    final totalExpense = cached.fold<double>(0, (sum, r) => sum + r.amount);
    return ProfitLoss(
      totalIncome: 0,
      totalExpense: totalExpense,
      netProfit: -totalExpense,
    );
  }
}
