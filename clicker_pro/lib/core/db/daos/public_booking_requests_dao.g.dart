// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_booking_requests_dao.dart';

// ignore_for_file: type=lint
mixin _$PublicBookingRequestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PublicBookingRequestsTableTable get publicBookingRequestsTable =>
      attachedDatabase.publicBookingRequestsTable;
  PublicBookingRequestsDaoManager get managers =>
      PublicBookingRequestsDaoManager(this);
}

class PublicBookingRequestsDaoManager {
  final _$PublicBookingRequestsDaoMixin _db;
  PublicBookingRequestsDaoManager(this._db);
  $$PublicBookingRequestsTableTableTableManager
  get publicBookingRequestsTable =>
      $$PublicBookingRequestsTableTableTableManager(
        _db.attachedDatabase,
        _db.publicBookingRequestsTable,
      );
}
