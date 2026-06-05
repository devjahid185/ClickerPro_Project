import 'package:drift/drift.dart';

import 'bookings_table.dart';

/// Composite key (bookingId, userId) — only one progress row per (event, staff)
/// pair.
@DataClassName('TaskProgressRow')
class TaskProgressTable extends Table {
  TextColumn get bookingId => text().references(BookingsTable, #id)();
  TextColumn get userId => text()();
  IntColumn get percentage => integer()(); // 0-100
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {bookingId, userId};
}
