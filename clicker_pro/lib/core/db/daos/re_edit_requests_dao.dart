// lib/core/db/daos/re_edit_requests_dao.dart
//
// DAO for ReEditRequests. Each booking has a 1-based round counter; the DAO
// computes the next round monotonically from the existing rows so callers can
// avoid race-prone client-side tracking.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/re_edit_requests_table.dart';

part 're_edit_requests_dao.g.dart';

@DriftAccessor(tables: [ReEditRequestsTable])
class ReEditRequestsDao extends DatabaseAccessor<AppDatabase>
    with _$ReEditRequestsDaoMixin {
  ReEditRequestsDao(super.db);

  Stream<List<ReEditRequestRow>> watchByBooking(String bookingId) {
    return (select(reEditRequestsTable)
          ..where((t) => t.bookingId.equals(bookingId))
          ..orderBy([(t) => OrderingTerm.asc(t.round)]))
        .watch();
  }

  /// Returns `max(round) + 1` for [bookingId], or `1` if no re-edits exist
  /// yet. The unique key `(bookingId, round)` guarantees correctness under
  /// the read-then-insert pattern callers use.
  Future<int> nextRoundFor(String bookingId) async {
    final maxExpr = reEditRequestsTable.round.max();
    final query = selectOnly(reEditRequestsTable)
      ..addColumns([maxExpr])
      ..where(reEditRequestsTable.bookingId.equals(bookingId));
    final row = await query.getSingleOrNull();
    final current = row?.read<int>(maxExpr);
    return (current ?? 0) + 1;
  }

  Future<void> upsert(ReEditRequestsTableCompanion row) async {
    await into(reEditRequestsTable).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(String id) async {
    await (delete(reEditRequestsTable)..where((t) => t.id.equals(id))).go();
  }
}
