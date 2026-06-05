// lib/core/db/daos/packages_dao.dart
//
// DAO for studio Packages. Packages are studio-scoped templates referenced by
// Booking.packageId.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/packages_table.dart';

part 'packages_dao.g.dart';

@DriftAccessor(tables: [PackagesTable])
class PackagesDao extends DatabaseAccessor<AppDatabase>
    with _$PackagesDaoMixin {
  PackagesDao(super.db);

  Stream<List<PackageRow>> watchAll() {
    return (select(
      packagesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<void> upsert(PackagesTableCompanion row) async {
    await into(packagesTable).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(String id) async {
    await (delete(packagesTable)..where((t) => t.id.equals(id))).go();
  }
}
