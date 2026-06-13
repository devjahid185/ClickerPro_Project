import 'package:drift/drift.dart';

@DataClassName('PackageRow')
class PackagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get studioId => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  RealColumn get basePrice => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get coverageHours => real().nullable()();
  RealColumn get extraHourRate => real().nullable()();
  TextColumn get printSize => text().nullable()();
  IntColumn get printQuantity => integer().nullable()();
  TextColumn get albumText => text().nullable()();
  TextColumn get deliveryMethod => text().nullable()();
  IntColumn get trailersPerEvent => integer().nullable()();
  IntColumn get fullVideosPerEvent => integer().nullable()();
  // MOD-25 team-composition: how many photographers / cinematographers the
  // package includes, and whether it designates a chief photographer.
  // Selecting the package in the booking form auto-fills these.
  IntColumn get photographerCount => integer().nullable()();
  IntColumn get cinematographerCount => integer().nullable()();
  BoolColumn get includesChief => boolean().withDefault(const Constant(false))();
  TextColumn get itemsJson => text().nullable()();
  TextColumn get inclusionsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
