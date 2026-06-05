// lib/features/profile/data/user_api.dart

import '../../../core/network/api_client.dart';

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _client.get('/api/profile') as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> patchProfile(
    Map<String, dynamic> partial,
  ) async {
    final r =
        await _client.patch('/api/profile', body: partial)
            as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> getLifetimeStats() async {
    try {
      final r = await _client.get('/api/profile/stats') as Map<String, dynamic>;
      return r;
    } catch (_) {
      // Backend may not yet expose this endpoint; surface nulls so UI still renders.
      return null;
    }
  }

  Future<Map<String, dynamic>> addGear({
    required String name,
    String? brand,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (brand != null) body['brand'] = brand;
    final r =
        await _client.post('/api/profile/gear', body: body)
            as Map<String, dynamic>;
    return (r['gear'] as Map).cast<String, dynamic>();
  }

  Future<void> removeGear(String gearId) async {
    await _client.delete('/api/profile/gear/$gearId');
  }
}
