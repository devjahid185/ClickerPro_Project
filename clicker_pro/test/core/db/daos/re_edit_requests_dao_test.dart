// Unit tests for ReEditRequestsDao.
//
// Covers insert + watchByBooking round-trip, delete, and the monotonic round
// counter `nextRoundFor` (returns 1 with no rows, 2 after round 1, 3 after
// round 2).
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

  test('upsert + watchByBooking emits rows ordered by round', () async {
    await seedBooking('b1');
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r2', bookingId: 'b1', round: 2, requestedByUserId: 'owner-1'),
    );
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r1', bookingId: 'b1', round: 1, requestedByUserId: 'owner-1'),
    );

    final rows = await db.reEditRequestsDao.watchByBooking('b1').first;
    expect(rows.map((r) => r.round).toList(), [1, 2]);
  });

  test('deleteById removes the row', () async {
    await seedBooking('b1');
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r1', bookingId: 'b1', round: 1, requestedByUserId: 'owner-1'),
    );

    await db.reEditRequestsDao.deleteById('r1');
    final rows = await db.reEditRequestsDao.watchByBooking('b1').first;
    expect(rows, isEmpty);
  });

  test('nextRoundFor returns 1, 2, 3 as rounds accumulate', () async {
    await seedBooking('b1');

    // No rows → 1.
    expect(await db.reEditRequestsDao.nextRoundFor('b1'), 1);

    // Round 1 inserted → next is 2.
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r1', bookingId: 'b1', round: 1, requestedByUserId: 'owner-1'),
    );
    expect(await db.reEditRequestsDao.nextRoundFor('b1'), 2);

    // Round 2 inserted → next is 3.
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r2', bookingId: 'b1', round: 2, requestedByUserId: 'owner-1'),
    );
    expect(await db.reEditRequestsDao.nextRoundFor('b1'), 3);
  });

  test('nextRoundFor is scoped per booking', () async {
    await seedBooking('b1');
    await seedBooking('b2');
    await db.reEditRequestsDao.upsert(
      reEdit(id: 'r1', bookingId: 'b1', round: 1, requestedByUserId: 'owner-1'),
    );

    expect(await db.reEditRequestsDao.nextRoundFor('b1'), 2);
    // b2 still has no re-edits.
    expect(await db.reEditRequestsDao.nextRoundFor('b2'), 1);
  });
}
