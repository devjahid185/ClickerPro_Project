import 'package:drift/drift.dart';

@DataClassName('TeamInviteRow')
class TeamInvitesTable extends Table {
  TextColumn get code => text()();
  TextColumn get ownerId => text()();
  TextColumn get role => text()(); // 'manager'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get consumedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
