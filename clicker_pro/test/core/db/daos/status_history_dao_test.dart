// Unit tests for StatusHistoryDao.
//
// Tier C (append-only) semantics: rows are only inserted, marked synced after
// a remote drain, or dropped specifically by the 409 reconciliation path.
//
// _Validates: Requirements 1.1, 7.2, 10.1_

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = makeMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedBooking(String id) async {
    await db.bookingsDao.upsert(
      booking(id: id, studioId: 's1', createdByUserId: 'owner-1'),
    );
  }

  test('append + watchByBooking emits in chronological order', () async {
    await seedBooking('b1');
    await db.statusHistoryDao.append(
      statusHistory(
        id: 'h1',
        bookingId: 'b1',
        fromStatus: 'pending',
        toStatus: 'confirmed',
        changedByUserId: 'owner-1',
        at: DateTime(2025, 1, 1, 9),
      ),
    );
    await db.statusHistoryDao.append(
      statusHistory(
        id: 'h2',
        bookingId: 'b1',
        fromStatus: 'confirmed',
        toStatus: 'inProgress',
        changedByUserId: 'owner-1',
        at: DateTime(2025, 1, 1, 12),
      ),
    );

    final rows = await db.statusHistoryDao.watchByBooking('b1').first;
    expect(rows.map((r) => r.id).toList(), ['h1', 'h2']);
  });

  test('markSynced sets remoteId and clears pending', () async {
    await seedBooking('b1');
    await db.statusHistoryDao.append(
      statusHistory(
        id: 'h1',
        bookingId: 'b1',
        fromStatus: 'pending',
        toStatus: 'confirmed',
        changedByUserId: 'owner-1',
        pending: true,
      ),
    );

    await db.statusHistoryDao.markSynced('h1', remoteId: 'remote-h1');

    final rows = await db.statusHistoryDao.watchByBooking('b1').first;
    expect(rows.single.remoteId, 'remote-h1');
    expect(rows.single.pending, isFalse);
  });

  test(
    'deletePendingForBooking only removes pending rows that match',
    () async {
      await seedBooking('b1');
      // Pending row that should be removed.
      await db.statusHistoryDao.append(
        statusHistory(
          id: 'h-pending',
          bookingId: 'b1',
          fromStatus: 'pending',
          toStatus: 'confirmed',
          changedByUserId: 'owner-1',
          pending: true,
        ),
      );
      // Synced row with the same from/to — must NOT be deleted.
      await db.statusHistoryDao.append(
        statusHistory(
          id: 'h-synced',
          bookingId: 'b1',
          fromStatus: 'pending',
          toStatus: 'confirmed',
          changedByUserId: 'owner-1',
          pending: false,
        ),
      );
      // Pending row with a different transition — must NOT be deleted.
      await db.statusHistoryDao.append(
        statusHistory(
          id: 'h-other',
          bookingId: 'b1',
          fromStatus: 'confirmed',
          toStatus: 'inProgress',
          changedByUserId: 'owner-1',
          pending: true,
        ),
      );

      final removed = await db.statusHistoryDao.deletePendingForBooking(
        'b1',
        fromStatus: 'pending',
        toStatus: 'confirmed',
      );
      expect(removed, 1);

      final rows = await db.statusHistoryDao.watchByBooking('b1').first;
      expect(rows.map((r) => r.id).toSet(), {'h-synced', 'h-other'});
    },
  );
}
