// lib/features/bookings/data/package_api.dart
//
// Wire-level methods for the studio-scoped Package endpoints against the
// Laravel backend. Shape translation lives in `server_wire.dart`.
//
// Laravel contract (routes/api.php + PackageController):
//   GET    /api/packages       → { data: [package…] }
//   POST   /api/packages       → { data: package } (201)
//   PATCH  /api/packages/:id   → { data: package }
//   DELETE /api/packages/:id   → { message: ok }

import '../../../core/network/api_client.dart';
import '../domain/package.dart';
import 'server_wire.dart';

class PackageApi {
  PackageApi(this._client);

  final ApiClient _client;

  /// `GET /api/packages`.
  Future<List<Package>> list() async {
    final r = await _client.get('/api/packages');
    return unwrapServerList(r)
        .map((e) => packageFromServer(e))
        .toList(growable: false);
  }

  /// `POST /api/packages` — response mapped with the submitted package as
  /// fallback so the LOCAL id (and the rich device-only fields the server
  /// does not persist) survive the round-trip.
  Future<Package> create(Package package) async {
    final r = await _client.post(
      '/api/packages',
      body: packageToServer(package),
    );
    return packageFromServer(unwrapServerMap(r), fallback: package);
  }

  /// `PATCH /api/packages/:id`. [partial] is the full local
  /// `Package.toJson()` map (both call sites pass exactly that).
  Future<Package> patch(String remoteId, Map<String, dynamic> partial) async {
    final local = Package.fromJson(partial);
    final r = await _client.patch(
      '/api/packages/$remoteId',
      body: packageToServer(local),
    );
    return packageFromServer(unwrapServerMap(r), fallback: local);
  }

  /// `DELETE /api/packages/:id`.
  Future<void> delete(String remoteId) async {
    await _client.delete('/api/packages/$remoteId');
  }
}
