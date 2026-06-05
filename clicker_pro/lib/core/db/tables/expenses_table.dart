import 'package:drift/drift.dart';

@DataClassName('ExpenseRow')
class ExpensesTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get eventId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptUrl => text().nullable()();
  DateTimeColumn get incurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
