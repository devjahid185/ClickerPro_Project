import 'package:drift/drift.dart';

import 'bookings_table.dart';

@DataClassName('PaymentRow')
class PaymentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get bookingId => text().references(BookingsTable, #id)();
  TextColumn get kind => text()(); // advance|due|extra
  RealColumn get amount => real()();
  TextColumn get method => text().nullable()(); // cash|bank|bkash|nagad|other
  TextColumn get note => text().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
