// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_progress_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskProgressTableTable get taskProgressTable =>
      attachedDatabase.taskProgressTable;
  TaskProgressDaoManager get managers => TaskProgressDaoManager(this);
}

class TaskProgressDaoManager {
  final _$TaskProgressDaoMixin _db;
  TaskProgressDaoManager(this._db);
  $$TaskProgressTableTableTableManager get taskProgressTable =>
      $$TaskProgressTableTableTableManager(
        _db.attachedDatabase,
        _db.taskProgressTable,
      );
}
