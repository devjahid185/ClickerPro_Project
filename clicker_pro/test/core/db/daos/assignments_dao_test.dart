// Unit tests for AssignmentsDao.
//
// Covers insert + watchByBooking round-trip, update via re-upsert, and delete.
//
// _Validates: Requirements 1.1, 7.2, 10.1_

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:drift/drift.dart' as d;
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

  test('upsert + watchByBooking emits the inserted assignments', () async {
    await seedBooking('b1');
    await db.assignmentsDao.upsert(
      assignment(id: 'a1', bookingId: 'b1', userId: 'u1'),
    );
    await db.assignmentsDao.upsert(
      assignment(
        id: 'a2',
        bookingId: 'b1',
        userId: 'u2',
        role: 'cinematographer',
        payout: 5000,
      ),
    );

    final rows = await db.assignmentsDao.watchByBooking('b1').first;
    expect(rows.length, 2);
    expect(rows.map((r) => r.id).toSet(), {'a1', 'a2'});
  });

  test('upsert with same id updates fields in place', () async {
    await seedBooking('b1');
    await db.assignmentsDao.upsert(
      assignment(id: 'a1', bookingId: 'b1', userId: 'u1', payout: 1000),
    );

    await db.assignmentsDao.upsert(
      AssignmentsTableCompanion.insert(
        id: 'a1',
        bookingId: 'b1',
        userId: 'u1',
        role: 'editor',
        payout: const d.Value(2500),
      ),
    );

    final rows = await db.assignmentsDao.watchByBooking('b1').first;
    expect(rows.length, 1);
    expect(rows.single.role, 'editor');
    expect(rows.single.payout, 2500);
  });

  test('deleteById removes the assignment', () async {
    await seedBooking('b1');
    await db.assignmentsDao.upsert(
      assignment(id: 'a1', bookingId: 'b1', userId: 'u1'),
    );

    await db.assignmentsDao.deleteById('a1');

    final rows = await db.assignmentsDao.watchByBooking('b1').first;
    expect(rows, isEmpty);
  });
}
