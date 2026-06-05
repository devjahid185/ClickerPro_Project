// GENERATED CODE - DO NOT MODIFY BY HAND

part of 're_edit_requests_dao.dart';

// ignore_for_file: type=lint
mixin _$ReEditRequestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReEditRequestsTableTable get reEditRequestsTable =>
      attachedDatabase.reEditRequestsTable;
  ReEditRequestsDaoManager get managers => ReEditRequestsDaoManager(this);
}

class ReEditRequestsDaoManager {
  final _$ReEditRequestsDaoMixin _db;
  ReEditRequestsDaoManager(this._db);
  $$ReEditRequestsTableTableTableManager get reEditRequestsTable =>
      $$ReEditRequestsTableTableTableManager(
        _db.attachedDatabase,
        _db.reEditRequestsTable,
      );
}
