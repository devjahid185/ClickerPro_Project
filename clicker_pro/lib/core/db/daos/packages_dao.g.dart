// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packages_dao.dart';

// ignore_for_file: type=lint
mixin _$PackagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PackagesTableTable get packagesTable => attachedDatabase.packagesTable;
  PackagesDaoManager get managers => PackagesDaoManager(this);
}

class PackagesDaoManager {
  final _$PackagesDaoMixin _db;
  PackagesDaoManager(this._db);
  $$PackagesTableTableTableManager get packagesTable =>
      $$PackagesTableTableTableManager(_db.attachedDatabase, _db.packagesTable);
}
