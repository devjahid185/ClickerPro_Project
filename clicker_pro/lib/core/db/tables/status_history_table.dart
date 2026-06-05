import 'package:drift/drift.dart';

import 'bookings_table.dart';

/// Tier C: append-only. No update path. updatedAt is unused; use [at] / createdAt
/// semantics via the [at] column.
@DataClassName('StatusHistoryEntryRow')
class StatusHistoryTable extends Table {
  TextColumn get id => text()(); // local UUID
  TextColumn get remoteId => text().nullable()();
  TextColumn get bookingId => text().references(BookingsTable, #id)();
  TextColumn get fromStatus => text()();
  TextColumn get toStatus => text()();
  TextColumn get changedByUserId => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get at => dateTime()();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
