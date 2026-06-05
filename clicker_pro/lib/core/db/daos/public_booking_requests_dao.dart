// lib/core/db/daos/public_booking_requests_dao.dart
//
// DAO for the owner-side mirror of pending public booking submissions. The
// table only stores rows in the `pending` status; once a request is approved
// or rejected the row is removed via [removeById].

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/public_booking_requests_table.dart';

part 'public_booking_requests_dao.g.dart';

@DriftAccessor(tables: [PublicBookingRequestsTable])
class PublicBookingRequestsDao extends DatabaseAccessor<AppDatabase>
    with _$PublicBookingRequestsDaoMixin {
  PublicBookingRequestsDao(super.db);

  Stream<List<PublicBookingRequestRow>> watchPending() {
    return (select(publicBookingRequestsTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.submittedAt)]))
        .watch();
  }

  Future<void> upsertPending(PublicBookingRequestsTableCompanion row) async {
    final withStatus = row.copyWith(
      status: const Value('pending'),
      updatedAt: Value(DateTime.now()),
    );
    await into(publicBookingRequestsTable).insertOnConflictUpdate(withStatus);
  }

  Future<void> removeById(String id) async {
    await (delete(
      publicBookingRequestsTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
