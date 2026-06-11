// lib/features/announcements/data/announcement_api.dart
//
// Owner→team announcement endpoints against the Laravel backend.
//
//   GET    /api/announcements          → { data: [row…] }   (team-scoped)
//   POST   /api/announcements          → { data: row } (201, owner only)
//   PATCH  /api/announcements/:id      → { data: row }
//   DELETE /api/announcements/:id      → { message: ok }
//   POST   /api/announcements/:id/read → { data: row }

import '../../../core/network/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementApi {
  AnnouncementApi(this._client);

  final ApiClient _client;

  Announcement _fromServer(Map<String, dynamic> j) => Announcement.fromJson({
    'id': j['id'],
    'ownerId': j['owner_id'] ?? j['ownerId'],
    'title': j['title'],
    'body': j['body'],
    'pinned': j['pinned'] is bool
        ? j['pinned']
        : (j['pinned']?.toString() == '1' || j['pinned']?.toString() == 'true'),
    'expiresAt': j['expires_at'] ?? j['expiresAt'],
    'createdAt': j['created_at'] ?? j['createdAt'],
    'readBy': j['read_by'] ?? j['readBy'] ?? const [],
  });

  Future<List<Announcement>> list() async {
    final r = await _client.get('/api/announcements');
    final raw = r is Map ? (r['data'] ?? r['announcements'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => _fromServer(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Announcement> create(Announcement draft) async {
    final r = await _client.post(
      '/api/announcements',
      body: draft.toCreateJson(),
    );
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return _fromServer(d);
  }

  Future<Announcement> update(String id, Map<String, dynamic> fields) async {
    final r = await _client.patch('/api/announcements/$id', body: fields);
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return _fromServer(d);
  }

  Future<void> remove(String id) async {
    await _client.delete('/api/announcements/$id');
  }

  Future<void> markRead(String id) async {
    await _client.post('/api/announcements/$id/read');
  }
}
