// Unit tests for PaymentsDao.
//
// Covers insert + watchByBooking round-trip, delete, and the per-booking
// aggregation invariant `(advance + due + extra) == total`.
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

  test('upsert + watchByBooking emits the inserted payments', () async {
    await seedBooking('b1');
    await db.paymentsDao.upsert(
      payment(id: 'p1', bookingId: 'b1', kind: 'advance', amount: 1000),
    );
    await db.paymentsDao.upsert(
      payment(id: 'p2', bookingId: 'b1', kind: 'due', amount: 500),
    );

    final rows = await db.paymentsDao.watchByBooking('b1').first;
    expect(rows.map((r) => r.id).toSet(), {'p1', 'p2'});
  });

  test('deleteById removes the payment row', () async {
    await seedBooking('b1');
    await db.paymentsDao.upsert(
      payment(id: 'p1', bookingId: 'b1', kind: 'advance', amount: 1000),
    );

    await db.paymentsDao.deleteById('p1');
    final rows = await db.paymentsDao.watchByBooking('b1').first;
    expect(rows, isEmpty);
  });

  test('aggregateForBooking returns zeros when no rows exist', () async {
    await seedBooking('b1');
    final agg = await db.paymentsDao.aggregateForBooking('b1');
    expect(agg.advance, 0);
    expect(agg.due, 0);
    expect(agg.extra, 0);
    expect(agg.total, 0);
  });

  test(
    'aggregateForBooking sums per-kind and total == advance + due + extra',
    () async {
      await seedBooking('b1');
      // Mix multiple rows per kind to verify SUM grouping.
      await db.paymentsDao.upsert(
        payment(id: 'p1', bookingId: 'b1', kind: 'advance', amount: 1000),
      );
      await db.paymentsDao.upsert(
        payment(id: 'p2', bookingId: 'b1', kind: 'advance', amount: 500),
      );
      await db.paymentsDao.upsert(
        payment(id: 'p3', bookingId: 'b1', kind: 'due', amount: 750),
      );
      await db.paymentsDao.upsert(
        payment(id: 'p4', bookingId: 'b1', kind: 'extra', amount: 250),
      );

      final agg = await db.paymentsDao.aggregateForBooking('b1');
      expect(agg.advance, 1500);
      expect(agg.due, 750);
      expect(agg.extra, 250);
      expect(agg.total, 2500);
      // Invariant: total == advance + due + extra.
      expect(agg.total, agg.advance + agg.due + agg.extra);
    },
  );

  test('aggregateForBooking does not leak across bookings', () async {
    await seedBooking('b1');
    await seedBooking('b2');
    await db.paymentsDao.upsert(
      payment(id: 'p1', bookingId: 'b1', kind: 'advance', amount: 1000),
    );
    await db.paymentsDao.upsert(
      payment(id: 'p2', bookingId: 'b2', kind: 'due', amount: 9000),
    );

    final aggB1 = await db.paymentsDao.aggregateForBooking('b1');
    expect(aggB1.advance, 1000);
    expect(aggB1.due, 0);
    expect(aggB1.total, 1000);

    final aggB2 = await db.paymentsDao.aggregateForBooking('b2');
    expect(aggB2.due, 9000);
    expect(aggB2.advance, 0);
    expect(aggB2.total, 9000);
  });
}
