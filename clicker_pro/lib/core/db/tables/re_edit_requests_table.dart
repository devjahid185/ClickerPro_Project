import 'package:drift/drift.dart';

import 'bookings_table.dart';

@DataClassName('ReEditRequestRow')
class ReEditRequestsTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get bookingId => text().references(BookingsTable, #id)();
  IntColumn get round => integer()(); // 1, 2, 3, ...
  TextColumn get editorUserId => text().nullable()();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get referenceImageUrlsJson => text().nullable()(); // up to 10
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending|inProgress|done|rejected
  TextColumn get requestedByUserId => text()();
  DateTimeColumn get requestedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookingId, round},
  ];
}
