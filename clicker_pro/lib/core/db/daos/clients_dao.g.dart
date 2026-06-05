// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_dao.dart';

// ignore_for_file: type=lint
mixin _$ClientsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClientsTableTable get clientsTable => attachedDatabase.clientsTable;
  ClientsDaoManager get managers => ClientsDaoManager(this);
}

class ClientsDaoManager {
  final _$ClientsDaoMixin _db;
  ClientsDaoManager(this._db);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db.attachedDatabase, _db.clientsTable);
}
