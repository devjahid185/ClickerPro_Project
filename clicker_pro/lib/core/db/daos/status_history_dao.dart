// lib/core/db/daos/status_history_dao.dart
//
// DAO for StatusHistory. The table is Tier C (append-only) — no update path is
// exposed; rows are only ever inserted, marked synced after a remote drain, or
// dropped specifically when the worker reconciles a 409 conflict.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/status_history_table.dart';

part 'status_history_dao.g.dart';

@DriftAccessor(tables: [StatusHistoryTable])
class StatusHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$StatusHistoryDaoMixin {
  StatusHistoryDao(super.db);

  Stream<List<StatusHistoryEntryRow>> watchByBooking(String bookingId) {
    return (select(statusHistoryTable)
          ..where((t) => t.bookingId.equals(bookingId))
          ..orderBy([(t) => OrderingTerm.asc(t.at)]))
        .watch();
  }

  /// Append a new history entry. Tier C semantics: callers must NOT pass an
  /// `id` that already exists; the unique-by-id table guards accidental
  /// overwrites.
  Future<void> append(StatusHistoryTableCompanion row) async {
    await into(statusHistoryTable).insert(row);
  }

  /// After a successful remote drain stamps the local row with the server-
  /// issued `remoteId` and clears the pending flag.
  Future<void> markSynced(String id, {required String remoteId}) async {
    await (update(statusHistoryTable)..where((t) => t.id.equals(id))).write(
      StatusHistoryTableCompanion(
        remoteId: Value(remoteId),
        pending: const Value(false),
      ),
    );
  }

  /// 409 reconciliation: the worker drops the locally-written pending entry
  /// (matching `bookingId` AND the unsuccessful from→to pair) so subsequent
  /// `refreshFromRemote` can land the server's authoritative history without
  /// duplication.
  Future<int> deletePendingForBooking(
    String bookingId, {
    required String fromStatus,
    required String toStatus,
  }) {
    return (delete(statusHistoryTable)..where(
          (t) =>
              t.bookingId.equals(bookingId) &
              t.fromStatus.equals(fromStatus) &
              t.toStatus.equals(toStatus) &
              t.pending.equals(true),
        ))
        .go();
  }
}
