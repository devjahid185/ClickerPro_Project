// lib/core/db/daos/assignments_dao.dart
//
// DAO for Assignments (per-booking team membership + payouts).

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/assignments_table.dart';

part 'assignments_dao.g.dart';

@DriftAccessor(tables: [AssignmentsTable])
class AssignmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AssignmentsDaoMixin {
  AssignmentsDao(super.db);

  Stream<List<AssignmentRow>> watchByBooking(String bookingId) {
    return (select(assignmentsTable)
          ..where((t) => t.bookingId.equals(bookingId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<void> upsert(AssignmentsTableCompanion row) async {
    await into(assignmentsTable).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(String id) async {
    await (delete(assignmentsTable)..where((t) => t.id.equals(id))).go();
  }
}
