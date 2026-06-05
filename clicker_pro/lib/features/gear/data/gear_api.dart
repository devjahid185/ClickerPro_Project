// lib/features/gear/data/gear_api.dart

import '../../../core/network/api_client.dart';
import '../domain/gear_item.dart';

class GearApi {
  GearApi(this._client);

  final ApiClient _client;

  Future<List<GearItem>> list() async {
    final r = await _client.get('/api/gear/my-gear') as Map<String, dynamic>;
    final raw = (r['gear'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(GearItem.fromJson)
        .toList(growable: false);
  }

  Future<GearItem> add(GearItem draft) async {
    final r =
        await _client.post('/api/gear/add', body: draft.toCreateJson())
            as Map<String, dynamic>;
    return GearItem.fromJson((r['gear'] as Map).cast<String, dynamic>());
  }

  Future<void> remove(String id) async {
    await _client.delete('/api/gear/$id');
  }
}
