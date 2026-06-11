import 'package:drift/drift.dart';

@DataClassName('UserRow')
class UsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()(); // owner|freelancer|both|manager
  TextColumn get ownerId => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get specialization => text().nullable()();
  TextColumn get vatBin => text().nullable()();
  TextColumn get studioAddress => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get bkash => text().nullable()();
  TextColumn get bankDetails => text().nullable()();
  TextColumn get signatureUrl => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get companyName => text().nullable()();
  IntColumn get totalEvents => integer().withDefault(const Constant(0))();
  IntColumn get totalRevenueMinor => integer().withDefault(const Constant(0))();
  IntColumn get totalClients => integer().withDefault(const Constant(0))();
  DateTimeColumn get statsRefreshedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
