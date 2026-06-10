// lib/core/db/daos/clients_dao.dart
//
// DAO for Clients. Local-first phone-prefix search powers the inline
// "create or pick existing client" flow on Booking_Edit_Screen.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/clients_table.dart';

part 'clients_dao.g.dart';

@DriftAccessor(tables: [ClientsTable])
class ClientsDao extends DatabaseAccessor<AppDatabase> with _$ClientsDaoMixin {
  ClientsDao(super.db);

  Stream<ClientRow?> watchById(String id) {
    return (select(
      clientsTable,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Phone-prefix autocomplete. Empty / whitespace prefix returns no rows.
  Future<List<ClientRow>> searchByPhone(String prefix) async {
    final trimmed = prefix.trim();
    if (trimmed.isEmpty) return const [];
    return (select(clientsTable)
          ..where((t) => t.phone.like('$trimmed%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(20))
        .get();
  }

  /// Exact phone lookup (used when the user picks a result from autocomplete
  /// and we need the full row).
  Future<ClientRow?> getByPhone(String phone) {
    return (select(
      clientsTable,
    )..where((t) => t.phone.equals(phone))).getSingleOrNull();
  }

  /// Looks up the local row a server row corresponds to. Used by the
  /// remote-refresh merge so a pulled server row updates the existing
  /// local row instead of inserting a duplicate under the server id.
  Future<ClientRow?> getByRemoteId(String remoteId) {
    return (select(clientsTable)
          ..where((t) => t.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsert(ClientsTableCompanion row) async {
    await into(clientsTable).insertOnConflictUpdate(row);
  }
}
