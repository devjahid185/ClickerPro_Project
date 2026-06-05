// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gear_dao.dart';

// ignore_for_file: type=lint
mixin _$GearDaoMixin on DatabaseAccessor<AppDatabase> {
  $GearItemsTableTable get gearItemsTable => attachedDatabase.gearItemsTable;
  GearDaoManager get managers => GearDaoManager(this);
}

class GearDaoManager {
  final _$GearDaoMixin _db;
  GearDaoManager(this._db);
  $$GearItemsTableTableTableManager get gearItemsTable =>
      $$GearItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.gearItemsTable,
      );
}
