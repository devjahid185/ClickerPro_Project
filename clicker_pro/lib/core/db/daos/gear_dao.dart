import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/gear_items_table.dart';

part 'gear_dao.g.dart';

@DriftAccessor(tables: [GearItemsTable])
class GearDao extends DatabaseAccessor<AppDatabase> with _$GearDaoMixin {
  GearDao(super.db);

  Stream<List<GearItemRow>> watchByUserId(String userId) {
    return (select(gearItemsTable)
          ..where((t) => t.userId.equals(userId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .watch();
  }

  Future<void> insertGear(GearItemsTableCompanion row) async {
    await into(gearItemsTable).insertOnConflictUpdate(row);
  }

  Future<void> markDeleted(String id) async {
    await (update(gearItemsTable)..where((t) => t.id.equals(id))).write(
      const GearItemsTableCompanion(deleted: Value(true), pending: Value(true)),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(gearItemsTable)..where((t) => t.id.equals(id))).go();
  }
}
