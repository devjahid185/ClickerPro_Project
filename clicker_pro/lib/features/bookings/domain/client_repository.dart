// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import 'client.dart';

/// Client CRUD with phone-prefix autocomplete and refresh-from-remote.
///
/// Local-first reads (Drift LIKE prefix) backed by background remote
/// refresh. Writes commit to Drift first and enqueue an outbox item.
abstract class ClientRepository {
  /// Phone-prefix autocomplete (LIKE match against the local cache).
  Future<List<Client>> searchByPhone(String prefix);

  /// Exact-match lookup by phone number; `null` when no row matches.
  Future<Client?> getByPhone(String phone);

  /// Watches a single client by local id; emits `null` when absent.
  Stream<Client?> watch(String localId);

  /// Upsert. Returns the persisted entity (with any server-side fields
  /// applied once the outbox drains).
  Future<Client> save(Client client);

  /// Pulls fresh rows from the server and reconciles into Drift.
  Future<void> refreshFromRemote();
}
