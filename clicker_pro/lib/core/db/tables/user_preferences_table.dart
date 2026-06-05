import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('UserPreferencesRow')
class UserPreferencesTable extends Table {
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get language => text().withDefault(const Constant('en'))();
  BoolColumn get distributionEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get vatEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get bengaliNumerals =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
