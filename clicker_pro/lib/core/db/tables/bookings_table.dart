import 'package:drift/drift.dart';

import 'clients_table.dart';
import 'packages_table.dart';

@DataClassName('BookingRow')
class BookingsTable extends Table {
  TextColumn get id => text()(); // local UUID
  TextColumn get remoteId => text().nullable()();
  TextColumn get studioId =>
      text()(); // owner.id for Owner/Both/Manager; self.id for Freelancer
  TextColumn get createdByUserId => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get eventType =>
      text()(); // wedding|holud|birthday|corporate|preWedding|other
  DateTimeColumn get date => dateTime()();
  TextColumn get startTime => text()(); // HH:mm
  TextColumn get endTime => text()(); // HH:mm
  TextColumn get shift => text()(); // day|night|both
  // MOD-07 v6: Client Name + Client Phone are required form fields that
  // live directly on the booking (not only via the linked ClientsTable).
  // clientName is nullable at the column level for backward compatibility
  // with older rows; the form enforces it as required at save time.
  TextColumn get clientName => text().nullable()();
  TextColumn get clientPhone => text().nullable()();
  TextColumn get venue => text().nullable()();
  BoolColumn get outdoor => boolean().withDefault(const Constant(false))();
  TextColumn get brideName => text().nullable()();
  TextColumn get groomName => text().nullable()();
  TextColumn get clientId => text().references(ClientsTable, #id).nullable()();
  TextColumn get packageId =>
      text().references(PackagesTable, #id).nullable()();
  RealColumn get customPrice => real().nullable()(); // when no package
  RealColumn get coverageHours => real().nullable()();
  RealColumn get extraHourRate => real().nullable()();
  TextColumn get driveLink => text().nullable()();
  TextColumn get clientRequirementsJson =>
      text().nullable()(); // freeform JSON blob
  TextColumn get notes => text().nullable()();
  TextColumn get chiefPhotographerUserId => text().nullable()();
  RealColumn get chiefHours => real().nullable()();
  BoolColumn get hidePaymentFromTeam =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
