// Unit tests for PackagesDao.
//
// Covers insert + watchAll round-trip, update via re-upsert, and delete.
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

  test(
    'upsert + watchAll emits the inserted packages sorted by name',
    () async {
      await db.packagesDao.upsert(
        package(id: 'p1', studioId: 's1', name: 'Silver', basePrice: 25000),
      );
      await db.packagesDao.upsert(
        package(id: 'p2', studioId: 's1', name: 'Gold', basePrice: 50000),
      );
      await db.packagesDao.upsert(
        package(id: 'p3', studioId: 's1', name: 'Platinum', basePrice: 90000),
      );

      final rows = await db.packagesDao.watchAll().first;
      expect(rows.map((r) => r.name).toList(), ['Gold', 'Platinum', 'Silver']);
    },
  );

  test('upsert with same id updates fields in place', () async {
    await db.packagesDao.upsert(
      package(id: 'p1', studioId: 's1', name: 'Silver', basePrice: 25000),
    );

    await db.packagesDao.upsert(
      PackagesTableCompanion.insert(
        id: 'p1',
        studioId: 's1',
        name: 'Silver Plus',
        basePrice: 30000,
      ),
    );

    final rows = await db.packagesDao.watchAll().first;
    expect(rows.length, 1);
    expect(rows.single.name, 'Silver Plus');
    expect(rows.single.basePrice, 30000);
  });

  test('deleteById removes the package row', () async {
    await db.packagesDao.upsert(
      package(id: 'p1', studioId: 's1', name: 'Silver', basePrice: 25000),
    );

    await db.packagesDao.deleteById('p1');
    final rows = await db.packagesDao.watchAll().first;
    expect(rows, isEmpty);
  });
}
