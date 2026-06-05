import 'package:drift/drift.dart';

@DataClassName('OutboxRow')
class OutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType =>
      text()(); // 'user' | 'gear' | 'preferences' | 'notification_prefs'
  TextColumn get entityId => text()();
  TextColumn get op => text()(); // 'create' | 'update' | 'delete'
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // 'pending' | 'manual_retry'
  TextColumn get lastError => text().nullable()();
}
