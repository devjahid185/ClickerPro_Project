import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<UserRow?> watchCurrent() {
    return (select(
      usersTable,
    )..where((t) => t.isCurrent.equals(true))).watchSingleOrNull();
  }

  Future<UserRow?> getCurrent() {
    return (select(
      usersTable,
    )..where((t) => t.isCurrent.equals(true))).getSingleOrNull();
  }

  Future<void> upsertCurrent(UsersTableCompanion row) async {
    await transaction(() async {
      await (update(usersTable)..where((t) => t.isCurrent.equals(true))).write(
        const UsersTableCompanion(isCurrent: Value(false)),
      );
      final withFlag = row.copyWith(isCurrent: const Value(true));
      await into(usersTable).insertOnConflictUpdate(withFlag);
    });
  }

  Future<void> markPending(String id, {bool pending = true}) async {
    await (update(usersTable)..where((t) => t.id.equals(id))).write(
      UsersTableCompanion(
        pending: Value(pending),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateDeletedAt(String id, DateTime? at) async {
    await (update(usersTable)..where((t) => t.id.equals(id))).write(
      UsersTableCompanion(deletedAt: Value(at)),
    );
  }

  Future<void> clearAll() async {
    await delete(usersTable).go();
  }
}
