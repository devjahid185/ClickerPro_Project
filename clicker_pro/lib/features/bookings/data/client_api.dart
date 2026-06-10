// lib/features/bookings/data/client_api.dart
//
// Wire-level methods for the Client (customer) endpoints against the
// Laravel backend. Shape translation lives in `server_wire.dart`.
//
// Laravel contract (routes/api.php + ClientController):
//   GET    /api/clients            → { data: [client…] }   (?search=)
//   POST   /api/clients            → { data: client } (201)
//   GET    /api/clients/:id        → { data: client+bookings }
//   PATCH  /api/clients/:id        → { data: client }
//   DELETE /api/clients/:id        → { message: ok }

import '../../../core/network/api_client.dart';
import '../domain/client.dart';
import 'server_wire.dart';

class ClientApi {
  ClientApi(this._client);

  final ApiClient _client;

  /// `GET /api/clients` — full owner-scoped client list.
  Future<List<Client>> list([Map<String, dynamic>? query]) async {
    final r = await _client.get('/api/clients', query: query);
    return unwrapServerList(r)
        .map((e) => clientFromServer(e))
        .toList(growable: false);
  }

  /// `GET /api/clients/:id`.
  Future<Client> get(String remoteId) async {
    final r = await _client.get('/api/clients/$remoteId');
    return clientFromServer(unwrapServerMap(r));
  }

  /// Phone-prefix autocomplete. The Laravel backend has no dedicated
  /// `/clients/search` route — the index endpoint's `search` parameter
  /// matches name/email/phone, which covers the phone-prefix case.
  Future<List<Client>> searchByPhone(String prefix) async {
    return list({'search': prefix});
  }

  /// `POST /api/clients` — create. Response mapped with the submitted
  /// client as fallback so the LOCAL id survives the round-trip.
  Future<Client> create(Client client) async {
    final r = await _client.post(
      '/api/clients',
      body: clientToServer(client),
    );
    return clientFromServer(unwrapServerMap(r), fallback: client);
  }

  /// `PATCH /api/clients/:id` — partial update. [partial] is the full
  /// local `Client.toJson()` map (both call sites pass exactly that).
  Future<Client> patch(String remoteId, Map<String, dynamic> partial) async {
    final local = Client.fromJson(partial);
    final r = await _client.patch(
      '/api/clients/$remoteId',
      body: clientToServer(local),
    );
    return clientFromServer(unwrapServerMap(r), fallback: local);
  }
}
