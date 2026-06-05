// lib/features/bookings/data/client_api.dart
//
// Wire-level methods for the Client (customer) endpoints. Wraps
// `ApiClient` calls and returns plain `Client` domain instances.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirements 13.7, 13.8.

import '../../../core/network/api_client.dart';
import '../domain/client.dart';

class ClientApi {
  ClientApi(this._client);

  final ApiClient _client;

  /// `GET /api/clients` — paginated client list.
  ///
  /// [query] is forwarded as the URL query map; common keys are
  /// `studioId`, `page`, `pageSize`. The default is "first page,
  /// default page size".
  Future<List<Client>> list([Map<String, dynamic>? query]) async {
    final r =
        await _client.get('/api/clients', query: query) as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map((e) => Client.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `GET /api/clients/:id`.
  Future<Client> get(String remoteId) async {
    final r =
        await _client.get('/api/clients/$remoteId') as Map<String, dynamic>;
    return Client.fromJson((r['client'] as Map).cast<String, dynamic>());
  }

  /// `GET /api/clients/search?phone=` — phone-prefix autocomplete.
  Future<List<Client>> searchByPhone(String prefix) async {
    final r =
        await _client.get('/api/clients/search', query: {'phone': prefix})
            as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map((e) => Client.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/clients` — create.
  Future<Client> create(Client client) async {
    final r =
        await _client.post('/api/clients', body: client.toJson())
            as Map<String, dynamic>;
    return Client.fromJson((r['client'] as Map).cast<String, dynamic>());
  }

  /// `PATCH /api/clients/:id` — partial update.
  Future<Client> patch(String remoteId, Map<String, dynamic> partial) async {
    final r =
        await _client.patch('/api/clients/$remoteId', body: partial)
            as Map<String, dynamic>;
    return Client.fromJson((r['client'] as Map).cast<String, dynamic>());
  }
}
