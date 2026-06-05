// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_history_dao.dart';

// ignore_for_file: type=lint
mixin _$StatusHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $StatusHistoryTableTable get statusHistoryTable =>
      attachedDatabase.statusHistoryTable;
  StatusHistoryDaoManager get managers => StatusHistoryDaoManager(this);
}

class StatusHistoryDaoManager {
  final _$StatusHistoryDaoMixin _db;
  StatusHistoryDaoManager(this._db);
  $$StatusHistoryTableTableTableManager get statusHistoryTable =>
      $$StatusHistoryTableTableTableManager(
        _db.attachedDatabase,
        _db.statusHistoryTable,
      );
}
