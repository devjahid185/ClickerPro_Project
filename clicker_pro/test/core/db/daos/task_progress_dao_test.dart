// Unit tests for TaskProgressDao.
//
// Covers insert + watchByBooking, watchOwn, and update via composite-key
// upsert. The composite primary key (bookingId, userId) means an upsert with
// the same pair replaces the row; there is no separate delete path on this
// DAO.
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

  test('upsert + watchByBooking emits all per-user rows', () async {
    await seedBooking('b1');
    await db.taskProgressDao.upsert(
      taskProgress(bookingId: 'b1', userId: 'u1', percentage: 25),
    );
    await db.taskProgressDao.upsert(
      taskProgress(bookingId: 'b1', userId: 'u2', percentage: 60),
    );

    final rows = await db.taskProgressDao.watchByBooking('b1').first;
    expect(rows.length, 2);
    expect(rows.map((r) => r.userId).toSet(), {'u1', 'u2'});
  });

  test('upsert replaces existing row by composite key', () async {
    await seedBooking('b1');
    await db.taskProgressDao.upsert(
      taskProgress(bookingId: 'b1', userId: 'u1', percentage: 10),
    );
    await db.taskProgressDao.upsert(
      taskProgress(
        bookingId: 'b1',
        userId: 'u1',
        percentage: 75,
        note: 'culling done',
      ),
    );

    final rows = await db.taskProgressDao.watchByBooking('b1').first;
    expect(rows.length, 1);
    expect(rows.single.percentage, 75);
    expect(rows.single.note, 'culling done');
  });

  test('watchOwn returns the user-specific row or null', () async {
    await seedBooking('b1');

    final firstEmission = await db.taskProgressDao
        .watchOwn(bookingId: 'b1', userId: 'u1')
        .first;
    expect(firstEmission, isNull);

    await db.taskProgressDao.upsert(
      taskProgress(bookingId: 'b1', userId: 'u1', percentage: 30),
    );

    final secondEmission = await db.taskProgressDao
        .watchOwn(bookingId: 'b1', userId: 'u1')
        .first;
    expect(secondEmission, isNotNull);
    expect(secondEmission!.percentage, 30);
  });
}
