// lib/features/gear/data/gear_api.dart
//
// Gear endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + GearController):
//   GET    /api/gear        → { data: [item…] }   (snake_case columns)
//   POST   /api/gear        → { data: item } (201)
//   DELETE /api/gear/:id    → { message: ok }
//
// Column map: value ⇄ purchase_value · addedAt ⇄ created_at. The server
// has no `brand` column yet — brand stays device-local until one exists.

import '../../../core/network/api_client.dart';
import '../domain/gear_item.dart';

class GearApi {
  GearApi(this._client);

  final ApiClient _client;

  GearItem _fromServer(Map<String, dynamic> j) => GearItem(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    brand: j['brand'] as String?,
    category: (j['category'] ?? 'Other').toString(),
    condition: j['condition'] as String?,
    value:
        double.tryParse((j['purchase_value'] ?? j['value'] ?? '0').toString()) ??
        0,
    addedAt: DateTime.tryParse((j['created_at'] ?? j['addedAt'] ?? '').toString()),
  );

  List<Map<String, dynamic>> _list(dynamic r) {
    final raw = r is Map ? (r['data'] ?? r['gear'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<GearItem>> list() async {
    final r = await _client.get('/api/gear');
    return _list(r).map(_fromServer).toList(growable: false);
  }

  Future<GearItem> add(GearItem draft) async {
    final r = await _client.post(
      '/api/gear',
      body: {
        'name': draft.name,
        'category': draft.category,
        'condition': ?draft.condition,
        'purchase_value': draft.value,
      },
    );
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final item = _fromServer(d);
    // Preserve the device-only brand the server cannot store yet.
    return GearItem(
      id: item.id.isNotEmpty ? item.id : draft.id,
      name: item.name.isNotEmpty ? item.name : draft.name,
      brand: draft.brand,
      category: item.category,
      condition: item.condition ?? draft.condition,
      value: item.value,
      addedAt: item.addedAt ?? draft.addedAt,
    );
  }

  Future<void> remove(String id) async {
    await _client.delete('/api/gear/$id');
  }
}
