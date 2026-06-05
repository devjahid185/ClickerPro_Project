// lib/features/bookings/data/package_api.dart
//
// Wire-level methods for the studio-scoped Package endpoints. Wraps
// `ApiClient` calls and returns plain `Package` domain instances.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.11.

import '../../../core/network/api_client.dart';
import '../domain/package.dart';

class PackageApi {
  PackageApi(this._client);

  final ApiClient _client;

  /// `GET /api/packages`.
  Future<List<Package>> list() async {
    final r = await _client.get('/api/packages') as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map((e) => Package.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/packages`.
  Future<Package> create(Package package) async {
    final r =
        await _client.post('/api/packages', body: package.toJson())
            as Map<String, dynamic>;
    return Package.fromJson((r['package'] as Map).cast<String, dynamic>());
  }

  /// `PATCH /api/packages/:id`.
  Future<Package> patch(String remoteId, Map<String, dynamic> partial) async {
    final r =
        await _client.patch('/api/packages/$remoteId', body: partial)
            as Map<String, dynamic>;
    return Package.fromJson((r['package'] as Map).cast<String, dynamic>());
  }

  /// `DELETE /api/packages/:id`.
  Future<void> delete(String remoteId) async {
    await _client.delete('/api/packages/$remoteId');
  }
}
