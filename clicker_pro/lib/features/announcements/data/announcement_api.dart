import '../../../core/network/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementApi {
  AnnouncementApi(this._client);

  final ApiClient _client;

  Future<List<Announcement>> list() async {
    final r = await _client.get('/api/announcements') as Map<String, dynamic>;
    final raw = (r['announcements'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList(growable: false);
  }

  Future<Announcement> create(Announcement draft) async {
    final r =
        await _client.post('/api/announcements', body: draft.toCreateJson())
            as Map<String, dynamic>;
    return Announcement.fromJson(
      (r['announcement'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Announcement> update(String id, Map<String, dynamic> fields) async {
    final r =
        await _client.patch('/api/announcements/$id', body: fields)
            as Map<String, dynamic>;
    return Announcement.fromJson(
      (r['announcement'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> remove(String id) async {
    await _client.delete('/api/announcements/$id');
  }

  Future<void> markRead(String id) async {
    await _client.post('/api/announcements/$id/read');
  }
}
