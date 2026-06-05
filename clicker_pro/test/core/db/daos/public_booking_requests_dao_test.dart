// Unit tests for PublicBookingRequestsDao.
//
// Covers upsertPending + watchPending round-trip (only `pending` rows are
// surfaced) and removal via removeById.
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

  test('upsertPending + watchPending emits the inserted request', () async {
    await db.publicBookingRequestsDao.upsertPending(
      publicBookingRequest(
        id: 'pbr-1',
        studioId: 's1',
        title: 'Garden Birthday',
        clientName: 'Alice',
        clientPhone: '01711000000',
      ),
    );

    final rows = await db.publicBookingRequestsDao.watchPending().first;
    expect(rows.length, 1);
    expect(rows.single.id, 'pbr-1');
    expect(rows.single.status, 'pending');
  });

  test('watchPending sorts by submittedAt desc', () async {
    await db.publicBookingRequestsDao.upsertPending(
      publicBookingRequest(
        id: 'older',
        studioId: 's1',
        title: 'Old',
        clientName: 'C1',
        clientPhone: '01711000001',
        submittedAt: DateTime(2025, 1, 1, 9),
      ),
    );
    await db.publicBookingRequestsDao.upsertPending(
      publicBookingRequest(
        id: 'newer',
        studioId: 's1',
        title: 'New',
        clientName: 'C2',
        clientPhone: '01711000002',
        submittedAt: DateTime(2025, 2, 1, 9),
      ),
    );

    final rows = await db.publicBookingRequestsDao.watchPending().first;
    expect(rows.map((r) => r.id).toList(), ['newer', 'older']);
  });

  test(
    'upsertPending forces status=pending even if caller passes another',
    () async {
      await db.publicBookingRequestsDao.upsertPending(
        publicBookingRequest(
          id: 'pbr-1',
          studioId: 's1',
          title: 'Test',
          clientName: 'C',
          clientPhone: '01711000000',
          status: 'approved',
        ),
      );

      final rows = await db.publicBookingRequestsDao.watchPending().first;
      expect(rows.single.status, 'pending');
    },
  );

  test('removeById deletes the request', () async {
    await db.publicBookingRequestsDao.upsertPending(
      publicBookingRequest(
        id: 'pbr-1',
        studioId: 's1',
        title: 'Test',
        clientName: 'C',
        clientPhone: '01711000000',
      ),
    );

    await db.publicBookingRequestsDao.removeById('pbr-1');

    final rows = await db.publicBookingRequestsDao.watchPending().first;
    expect(rows, isEmpty);
  });
}
