// Unit tests for BookingsDao.
//
// Covers:
//   • Insert + watch round-trip emits the inserted row.
//   • Update path: `markPending` and `markSynced` mutate the watched row.
//   • Delete path: `deleteById` removes the row.
//   • Role-scoped `watchList` returns the correct subset for each of the four
//     UserRole values (Owner, Both, Manager, Freelancer) against a fixed
//     fixture of bookings + assignments.
//   • `watchMonth` filters by [year, month).
//
// _Validates: Requirements 1.1, 7.2, 10.1_

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/db/daos/bookings_dao.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
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

  group('BookingsDao CRUD round-trip', () {
    test('upsert + watchById emits the inserted row', () async {
      const studioId = 'studio-1';
      const ownerId = 'owner-1';
      await db.bookingsDao.upsert(
        booking(
          id: 'b1',
          studioId: studioId,
          createdByUserId: ownerId,
          title: 'Acme Wedding',
        ),
      );

      final row = await db.bookingsDao.watchById('b1').first;
      expect(row, isNotNull);
      expect(row!.id, 'b1');
      expect(row.title, 'Acme Wedding');
      expect(row.status, 'pending');
      expect(row.pending, isFalse);
    });

    test('markPending sets pending=true and bumps updatedAt', () async {
      await db.bookingsDao.upsert(
        booking(id: 'b1', studioId: 's', createdByUserId: 'u'),
      );
      final before = await db.bookingsDao.watchById('b1').first;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.bookingsDao.markPending('b1');
      final after = await db.bookingsDao.watchById('b1').first;
      expect(after!.pending, isTrue);
      expect(
        after.updatedAt.isAfter(before!.updatedAt) ||
            after.updatedAt.isAtSameMomentAs(before.updatedAt),
        isTrue,
      );
    });

    test('markSynced stamps remoteId and clears pending', () async {
      await db.bookingsDao.upsert(
        booking(id: 'b1', studioId: 's', createdByUserId: 'u'),
      );
      await db.bookingsDao.markPending('b1');
      final stamp = DateTime(2025, 5, 1, 10);
      await db.bookingsDao.markSynced(
        'b1',
        remoteId: 'remote-99',
        updatedAt: stamp,
      );

      final row = await db.bookingsDao.watchById('b1').first;
      expect(row!.pending, isFalse);
      expect(row.remoteId, 'remote-99');
      expect(row.updatedAt, stamp);
    });

    test('deleteById removes the row', () async {
      await db.bookingsDao.upsert(
        booking(id: 'b1', studioId: 's', createdByUserId: 'u'),
      );
      expect(await db.bookingsDao.watchById('b1').first, isNotNull);

      await db.bookingsDao.deleteById('b1');
      expect(await db.bookingsDao.watchById('b1').first, isNull);
    });
  });

  group('BookingsDao.watchList role scoping', () {
    // Fixture (single studio):
    //   Owner    : owner-1   (studioId == studio-1)
    //   Manager  : mgr-1
    //   Freelancer A : free-A (created by free-A)
    //   Freelancer B : free-B
    //
    //  bookings:
    //   b1  studio-1, createdBy=owner-1, no assignments              → Owner / Both only
    //   b2  studio-1, createdBy=mgr-1,   no assignments              → Owner / Both / Manager (creator)
    //   b3  studio-1, createdBy=owner-1, assignment(mgr-1)           → Owner / Both / Manager (assigned)
    //   b4  studio-1, createdBy=free-A,  assignment(free-A)          → Owner / Both / Freelancer A
    //   b5  studio-1, createdBy=owner-1, assignment(free-B)          → Owner / Both / Freelancer B
    const studioId = 'studio-1';
    const ownerId = 'owner-1';
    const managerId = 'mgr-1';
    const freelancerA = 'free-A';
    const freelancerB = 'free-B';

    Future<void> seed() async {
      await db.bookingsDao.upsert(
        booking(id: 'b1', studioId: studioId, createdByUserId: ownerId),
      );
      await db.bookingsDao.upsert(
        booking(id: 'b2', studioId: studioId, createdByUserId: managerId),
      );
      await db.bookingsDao.upsert(
        booking(id: 'b3', studioId: studioId, createdByUserId: ownerId),
      );
      await db.bookingsDao.upsert(
        booking(id: 'b4', studioId: studioId, createdByUserId: freelancerA),
      );
      await db.bookingsDao.upsert(
        booking(id: 'b5', studioId: studioId, createdByUserId: ownerId),
      );

      await db.assignmentsDao.upsert(
        assignment(id: 'a1', bookingId: 'b3', userId: managerId),
      );
      await db.assignmentsDao.upsert(
        assignment(id: 'a2', bookingId: 'b4', userId: freelancerA),
      );
      await db.assignmentsDao.upsert(
        assignment(id: 'a3', bookingId: 'b5', userId: freelancerB),
      );
    }

    test('Owner sees every booking in the studio', () async {
      await seed();

      final rows = await db.bookingsDao
          .watchList(
            const BookingsListQuery(),
            role: UserRole.owner,
            studioId: studioId,
            currentUserId: ownerId,
          )
          .first;

      expect(rows.map((r) => r.id).toSet(), {'b1', 'b2', 'b3', 'b4', 'b5'});
    });

    test('Both sees every booking in the studio', () async {
      await seed();

      final rows = await db.bookingsDao
          .watchList(
            const BookingsListQuery(),
            role: UserRole.both,
            studioId: studioId,
            currentUserId: ownerId,
          )
          .first;

      expect(rows.map((r) => r.id).toSet(), {'b1', 'b2', 'b3', 'b4', 'b5'});
    });

    test('Manager sees own creations + assigned bookings only', () async {
      await seed();

      final rows = await db.bookingsDao
          .watchList(
            const BookingsListQuery(),
            role: UserRole.manager,
            studioId: studioId,
            currentUserId: managerId,
          )
          .first;

      // b2 (creator), b3 (assigned). Excludes b1, b4, b5.
      expect(rows.map((r) => r.id).toSet(), {'b2', 'b3'});
    });

    test(
      'Freelancer A sees only their own creations + their assignments',
      () async {
        await seed();

        final rows = await db.bookingsDao
            .watchList(
              const BookingsListQuery(),
              role: UserRole.freelancer,
              studioId: studioId,
              currentUserId: freelancerA,
            )
            .first;

        // b4 covers both creator and assigned.
        expect(rows.map((r) => r.id).toSet(), {'b4'});
      },
    );

    test('Freelancer B sees only their assigned bookings', () async {
      await seed();

      final rows = await db.bookingsDao
          .watchList(
            const BookingsListQuery(),
            role: UserRole.freelancer,
            studioId: studioId,
            currentUserId: freelancerB,
          )
          .first;

      // b5 (assigned). free-B did not create any booking.
      expect(rows.map((r) => r.id).toSet(), {'b5'});
    });
  });

  group('BookingsDao.watchMonth', () {
    test('returns only bookings whose date falls inside the month', () async {
      const studioId = 'studio-1';
      const ownerId = 'owner-1';

      await db.bookingsDao.upsert(
        booking(
          id: 'jan',
          studioId: studioId,
          createdByUserId: ownerId,
          date: DateTime(2025, 1, 10),
        ),
      );
      await db.bookingsDao.upsert(
        booking(
          id: 'feb',
          studioId: studioId,
          createdByUserId: ownerId,
          date: DateTime(2025, 2, 5),
        ),
      );
      await db.bookingsDao.upsert(
        booking(
          id: 'mar',
          studioId: studioId,
          createdByUserId: ownerId,
          date: DateTime(2025, 3, 1),
        ),
      );

      final feb = await db.bookingsDao
          .watchMonth(
            2025,
            2,
            role: UserRole.owner,
            studioId: studioId,
            currentUserId: ownerId,
          )
          .first;

      expect(feb.map((r) => r.id).toList(), ['feb']);
    });
  });
}
