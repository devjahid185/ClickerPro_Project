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
      // Cache the result locally.
      final rows = remote.map((e) => _modelToCompanion(e)).toList();
      await _dao.clearAll();
      if (rows.isNotEmpty) {
        await _dao.upsertAll(rows);
      }
      return remote;
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
      await _dao.upsert(_modelToCompanion(saved));
      return saved;
    } catch (_) {
      // If we can't reach the API, save locally as pending.
      final pending = draft;
      await _dao.upsert(_modelToCompanion(pending, pending: true));
      return pending;
    }
  }

  @override
  Future<ProfitLoss> profitLoss() async {
    try {
      return await _api.profit();
    } catch (_) {
      // Calculate from local cache when offline.
      final cached = await _dao.getAll();
      final totalExpense = cached.fold<double>(0, (sum, r) => sum + r.amount);
      return ProfitLoss(
        totalIncome: 0,
        totalExpense: totalExpense,
        netProfit: -totalExpense,
      );
    }
  }
}
