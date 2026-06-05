import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('GearItemRow')
class GearItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
