import 'package:drift/drift.dart';

import 'bookings_table.dart';

@DataClassName('AssignmentRow')
class AssignmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get bookingId => text().references(BookingsTable, #id)();
  TextColumn get userId => text()(); // staff
  TextColumn get role =>
      text()(); // photographer|cinematographer|editor|assistant|drone
  RealColumn get payout => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
