import 'package:drift/drift.dart';

/// Owner-side mirror of pending public requests (for offline visibility of the
/// pending list). The visitor-side submission is fire-and-forget; nothing local
/// on the visitor's device.
@DataClassName('PublicBookingRequestRow')
class PublicBookingRequestsTable extends Table {
  TextColumn get id => text()(); // server-issued
  TextColumn get studioId => text()();
  TextColumn get title => text()();
  TextColumn get eventType => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get shift => text()();
  TextColumn get venue => text().nullable()();
  TextColumn get brideName => text().nullable()();
  TextColumn get groomName => text().nullable()();
  TextColumn get clientName => text()();
  TextColumn get clientPhone => text()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending|approved|rejected
  DateTimeColumn get submittedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
