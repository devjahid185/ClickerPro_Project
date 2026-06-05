// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignments_dao.dart';

// ignore_for_file: type=lint
mixin _$AssignmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssignmentsTableTable get assignmentsTable =>
      attachedDatabase.assignmentsTable;
  AssignmentsDaoManager get managers => AssignmentsDaoManager(this);
}

class AssignmentsDaoManager {
  final _$AssignmentsDaoMixin _db;
  AssignmentsDaoManager(this._db);
  $$AssignmentsTableTableTableManager get assignmentsTable =>
      $$AssignmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.assignmentsTable,
      );
}
