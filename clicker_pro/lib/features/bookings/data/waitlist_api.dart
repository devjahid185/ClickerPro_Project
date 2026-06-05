import '../../../core/network/api_client.dart';
import '../domain/waitlist_entry.dart';

/// Waitlist REST client — talks to `/api/waitlist` (owner-scoped on the
/// server). The backend stores status as an uppercase enum (WAITING/…);
/// [WaitlistEntry.fromJson] expects the lowercase Dart enum name, so we
/// lower-case `status` on the way in.
class WaitlistApi {
  WaitlistApi(this._client);

  final ApiClient _client;

  Future<List<WaitlistEntry>> list() async {
    final r = await _client.get('/api/waitlist') as Map<String, dynamic>;
    final rows = (r['data'] as List? ?? const []);
    return rows
        .map((e) => WaitlistEntry.fromJson(_normalize(e)))
        .toList(growable: false);
  }

  Future<WaitlistEntry> create(WaitlistEntry draft) async {
    final r = await _client.post(
      '/api/waitlist',
      body: <String, dynamic>{
        'clientName': draft.clientName,
        'phone': draft.phone,
        'preferredDate': draft.preferredDate.toIso8601String(),
        if (draft.note != null) 'note': draft.note,
        'status': draft.status.name.toUpperCase(),
      },
    ) as Map<String, dynamic>;
    return WaitlistEntry.fromJson(_normalize(r['data']));
  }

  Future<void> update(WaitlistEntry entry) async {
    await _client.patch(
      '/api/waitlist/${entry.id}',
      body: <String, dynamic>{
        'clientName': entry.clientName,
        'phone': entry.phone,
        'preferredDate': entry.preferredDate.toIso8601String(),
        'note': entry.note,
        'status': entry.status.name.toUpperCase(),
      },
    );
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/waitlist/$id');
  }

  /// Coerce the server row into the shape [WaitlistEntry.fromJson] wants
  /// (lowercase status enum name).
  Map<String, dynamic> _normalize(Object? raw) {
    final m = (raw as Map).cast<String, dynamic>();
    final status = m['status'];
    return <String, dynamic>{
      ...m,
      if (status is String) 'status': status.toLowerCase(),
    };
  }
}
