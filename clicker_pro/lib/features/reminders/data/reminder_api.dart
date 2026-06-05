import '../../../core/network/api_client.dart';
import '../domain/reminder.dart';

/// Reminder REST client — talks to `/api/reminders` (owner-scoped on the
/// server). The backend stores `type`/`channel` as uppercase enums
/// (PAYMENT/WHATSAPP/…); [Reminder.fromJson] expects the lowercase Dart enum
/// names, so we lower-case them on the way in.
class ReminderApi {
  ReminderApi(this._client);

  final ApiClient _client;

  Future<List<Reminder>> list() async {
    final r = await _client.get('/api/reminders') as Map<String, dynamic>;
    final rows = (r['data'] as List? ?? const []);
    return rows
        .map((e) => Reminder.fromJson(_normalize(e)))
        .toList(growable: false);
  }

  Future<Reminder> create(Reminder draft) async {
    final r = await _client.post(
      '/api/reminders',
      body: <String, dynamic>{
        'bookingId': draft.bookingId,
        'type': draft.type.name.toUpperCase(),
        'scheduledDate': draft.scheduledDate.toIso8601String(),
        'sent': draft.sent,
        'channel': draft.channel.name.toUpperCase(),
      },
    ) as Map<String, dynamic>;
    return Reminder.fromJson(_normalize(r['data']));
  }

  Future<void> update(Reminder reminder) async {
    await _client.patch(
      '/api/reminders/${reminder.id}',
      body: <String, dynamic>{
        'bookingId': reminder.bookingId,
        'type': reminder.type.name.toUpperCase(),
        'scheduledDate': reminder.scheduledDate.toIso8601String(),
        'sent': reminder.sent,
        'channel': reminder.channel.name.toUpperCase(),
      },
    );
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/reminders/$id');
  }

  /// Coerce the server row into the shape [Reminder.fromJson] wants
  /// (lowercase `type`/`channel` enum names).
  Map<String, dynamic> _normalize(Object? raw) {
    final m = (raw as Map).cast<String, dynamic>();
    final type = m['type'];
    final channel = m['channel'];
    return <String, dynamic>{
      ...m,
      if (type is String) 'type': type.toLowerCase(),
      if (channel is String) 'channel': channel.toLowerCase(),
    };
  }
}
