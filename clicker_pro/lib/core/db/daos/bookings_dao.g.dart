// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_dao.dart';

// ignore_for_file: type=lint
mixin _$BookingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookingsTableTable get bookingsTable => attachedDatabase.bookingsTable;
  $AssignmentsTableTable get assignmentsTable =>
      attachedDatabase.assignmentsTable;
  BookingsDaoManager get managers => BookingsDaoManager(this);
}

class BookingsDaoManager {
  final _$BookingsDaoMixin _db;
  BookingsDaoManager(this._db);
  $$BookingsTableTableTableManager get bookingsTable =>
      $$BookingsTableTableTableManager(_db.attachedDatabase, _db.bookingsTable);
  $$AssignmentsTableTableTableManager get assignmentsTable =>
      $$AssignmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.assignmentsTable,
      );
}
