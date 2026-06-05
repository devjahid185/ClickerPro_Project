// Unit tests for ClientsDao.
//
// Covers insert, watch round-trip, update via second upsert, phone-prefix
// search, and exact-phone lookup.
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

  test('upsert + watchById emits the inserted client', () async {
    await db.clientsDao.upsert(
      client(
        id: 'c1',
        studioId: 's1',
        name: 'Alice',
        phone: '01711000000',
        email: 'alice@example.com',
      ),
    );

    final row = await db.clientsDao.watchById('c1').first;
    expect(row, isNotNull);
    expect(row!.name, 'Alice');
    expect(row.phone, '01711000000');
    expect(row.email, 'alice@example.com');
  });

  test('upsert with the same id updates fields in place', () async {
    await db.clientsDao.upsert(
      client(id: 'c1', studioId: 's1', name: 'Alice', phone: '01711000000'),
    );

    await db.clientsDao.upsert(
      ClientsTableCompanion.insert(
        id: 'c1',
        studioId: 's1',
        name: 'Alice Updated',
        phone: '01711000000',
        email: const d.Value('alice2@example.com'),
      ),
    );

    final row = await db.clientsDao.watchById('c1').first;
    expect(row!.name, 'Alice Updated');
    expect(row.email, 'alice2@example.com');
  });

  test('searchByPhone returns prefix matches sorted by name', () async {
    await db.clientsDao.upsert(
      client(id: 'c1', studioId: 's1', name: 'Bob', phone: '01711100000'),
    );
    await db.clientsDao.upsert(
      client(id: 'c2', studioId: 's1', name: 'Alice', phone: '01711200000'),
    );
    await db.clientsDao.upsert(
      client(id: 'c3', studioId: 's1', name: 'Carol', phone: '01999999999'),
    );

    final results = await db.clientsDao.searchByPhone('01711');
    expect(results.map((r) => r.id).toList(), ['c2', 'c1']);
  });

  test('searchByPhone returns empty for blank prefix', () async {
    await db.clientsDao.upsert(
      client(id: 'c1', studioId: 's1', name: 'Bob', phone: '01711100000'),
    );

    expect(await db.clientsDao.searchByPhone(''), isEmpty);
    expect(await db.clientsDao.searchByPhone('   '), isEmpty);
  });

  test('getByPhone returns exact match or null', () async {
    await db.clientsDao.upsert(
      client(id: 'c1', studioId: 's1', name: 'Bob', phone: '01711100000'),
    );

    final hit = await db.clientsDao.getByPhone('01711100000');
    expect(hit, isNotNull);
    expect(hit!.id, 'c1');

    final miss = await db.clientsDao.getByPhone('00000000000');
    expect(miss, isNull);
  });
}
