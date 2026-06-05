import 'package:drift/drift.dart';
import 'users_table.dart';

@DataClassName('NotificationPreferencesRow')
class NotificationPreferencesTable extends Table {
  TextColumn get userId => text().references(UsersTable, #id)();
  BoolColumn get eventReminders =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get paymentDue => boolean().withDefault(const Constant(true))();
  BoolColumn get teamMessages => boolean().withDefault(const Constant(true))();
  BoolColumn get announcements => boolean().withDefault(const Constant(true))();
  BoolColumn get marketing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
