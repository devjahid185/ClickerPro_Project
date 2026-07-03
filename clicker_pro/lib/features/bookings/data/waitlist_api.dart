import '../../../core/network/api_client.dart';
import '../domain/waitlist_entry.dart';

/// Waitlist REST client — talks to `/api/waitlist` (owner-scoped on the
/// server).
///
/// Laravel contract (WaitlistController):
///   POST  /api/waitlist   validates `name` (required), `phone`, `email`,
///                          `date_requested` (date), `notes`
///   GET   /api/waitlist   → { data: [ {id, owner_id, name, phone,
///                          date_requested, notes, created_at, …} ] }
///
/// The app model still speaks the older camelCase shape (clientName /
/// preferredDate / note), so [_normalize] translates each server row. The
/// old client sent that camelCase shape on POST too — the server's required
/// `name` was never present, so every add failed 422 ("Waitlist এ বুকিং এড
/// করা যায় না"). Status is a local display concept; the server doesn't
/// store one, so rows default to `waiting`.
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
        'name': draft.clientName,
        'phone': draft.phone,
        // Laravel's `date` rule accepts a plain calendar date; the time part
        // is meaningless for a waitlist wish-date.
        'date_requested':
            draft.preferredDate.toIso8601String().split('T').first,
        if (draft.note != null && draft.note!.trim().isNotEmpty)
          'notes': draft.note,
      },
    ) as Map<String, dynamic>;
    return WaitlistEntry.fromJson(_normalize(r['data']));
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/waitlist/$id');
  }

  /// Coerce a Laravel waitlist row into the shape [WaitlistEntry.fromJson]
  /// wants: string id, camelCase keys, lowercase status with a `waiting`
  /// default (the server does not persist a status).
  Map<String, dynamic> _normalize(Object? raw) {
    final m = (raw as Map).cast<String, dynamic>();
    final status = m['status'];
    final date = m['date_requested'] ?? m['preferredDate'] ?? m['created_at'];
    return <String, dynamic>{
      'id': '${m['id']}',
      'ownerId': '${m['owner_id'] ?? m['ownerId'] ?? ''}',
      'clientName': (m['name'] ?? m['clientName'] ?? '—').toString(),
      'phone': (m['phone'] ?? '').toString(),
      'preferredDate': (date ?? DateTime.now().toIso8601String()).toString(),
      if (m['notes'] != null || m['note'] != null)
        'note': (m['notes'] ?? m['note']).toString(),
      'status': status is String ? status.toLowerCase() : 'waiting',
    };
  }
}
