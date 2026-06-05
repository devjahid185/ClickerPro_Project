import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [ExpensesTable])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<List<ExpenseRow>> getAll() => select(expensesTable).get();

  Future<List<ExpenseRow>> getPending() {
    return (select(expensesTable)
          ..where((t) => t.pending.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> upsert(ExpensesTableCompanion row) async {
    await into(expensesTable).insertOnConflictUpdate(row);
  }

  Future<void> upsertAll(List<ExpensesTableCompanion> rows) async {
    await batch((b) {
      for (final row in rows) {
        b.insert(expensesTable, row, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<void> deleteById(String id) async {
    await (delete(expensesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await delete(expensesTable).go();
  }
}
