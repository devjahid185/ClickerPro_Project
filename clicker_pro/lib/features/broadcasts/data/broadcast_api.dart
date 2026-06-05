import '../../../core/network/api_client.dart';
import '../domain/broadcast.dart';

/// Read-only client for platform broadcasts. The backend returns only
/// ACTIVE rows from `GET /api/broadcasts`, newest first.
class BroadcastApi {
  BroadcastApi(this._client);

  final ApiClient _client;

  Future<List<Broadcast>> list() async {
    final r = await _client.get('/api/broadcasts') as Map<String, dynamic>;
    final rows = (r['data'] as List?) ?? const <dynamic>[];
    return rows
        .cast<Map<String, dynamic>>()
        .map(Broadcast.fromJson)
        .toList(growable: false);
  }
}
