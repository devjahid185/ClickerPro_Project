import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/outbox_table.dart';

part 'outbox_dao.g.dart';

@DriftAccessor(tables: [OutboxTable])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  Future<int> enqueue(OutboxTableCompanion row) =>
      into(outboxTable).insert(row);

  Stream<List<OutboxRow>> watchPending() {
    return (select(outboxTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<OutboxRow>> watchAll() {
    return (select(
      outboxTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<void> markAttempt(
    int id, {
    required int attempts,
    DateTime? nextAttemptAt,
    String? lastError,
  }) async {
    await (update(outboxTable)..where((t) => t.id.equals(id))).write(
      OutboxTableCompanion(
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(lastError),
      ),
    );
  }

  Future<void> markManualRetry(int id, {required String lastError}) async {
    await (update(outboxTable)..where((t) => t.id.equals(id))).write(
      OutboxTableCompanion(
        status: const Value('manual_retry'),
        lastError: Value(lastError),
      ),
    );
  }

  /// Flips a `manual_retry` row back to `pending` and clears its
  /// scheduled attempt time so the worker picks it up on the next
  /// drain. Used by the Sync sheet's "Retry" affordance.
  Future<void> requeueManualRetry(int id) async {
    await (update(outboxTable)..where((t) => t.id.equals(id))).write(
      const OutboxTableCompanion(
        status: Value('pending'),
        attempts: Value(0),
        nextAttemptAt: Value(null),
        lastError: Value(null),
      ),
    );
  }

  /// Watches every row currently in `manual_retry` state — newest first.
  /// The Sync sheet uses this stream to render the retry list.
  Stream<List<OutboxRow>> watchManualRetry() {
    return (select(outboxTable)
          ..where((t) => t.status.equals('manual_retry'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> deleteItem(int id) async {
    await (delete(outboxTable)..where((t) => t.id.equals(id))).go();
  }
}
