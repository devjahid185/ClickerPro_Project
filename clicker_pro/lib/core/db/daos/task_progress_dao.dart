// lib/core/db/daos/task_progress_dao.dart
//
// DAO for per-staff task progress. Composite primary key (bookingId, userId)
// guarantees one row per (event, staff) pair; upserts replace in place.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/task_progress_table.dart';

part 'task_progress_dao.g.dart';

@DriftAccessor(tables: [TaskProgressTable])
class TaskProgressDao extends DatabaseAccessor<AppDatabase>
    with _$TaskProgressDaoMixin {
  TaskProgressDao(super.db);

  Stream<List<TaskProgressRow>> watchByBooking(String bookingId) {
    return (select(taskProgressTable)
          ..where((t) => t.bookingId.equals(bookingId))
          ..orderBy([(t) => OrderingTerm.asc(t.userId)]))
        .watch();
  }

  /// Watches the current user's own progress row for [bookingId]. Returns
  /// `null` when no row exists yet (the staff member has not posted progress).
  Stream<TaskProgressRow?> watchOwn({
    required String bookingId,
    required String userId,
  }) {
    return (select(taskProgressTable)..where(
          (t) => t.bookingId.equals(bookingId) & t.userId.equals(userId),
        ))
        .watchSingleOrNull();
  }

  Future<void> upsert(TaskProgressTableCompanion row) async {
    await into(taskProgressTable).insertOnConflictUpdate(row);
  }
}
