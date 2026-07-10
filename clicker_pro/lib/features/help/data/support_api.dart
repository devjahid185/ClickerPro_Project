// lib/features/help/data/support_api.dart
//
// Support endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + FaqController/SupportController):
//   GET  /api/faqs     → { data: [faq…] }       (auth required)
//   POST /api/support  → { data: ticket } (201)  body: {subject, body}

import '../../../core/network/api_client.dart';
import '../domain/faq_entry.dart';
import '../domain/support_ticket_draft.dart';

class SupportApi {
  SupportApi(this._client);

  final ApiClient _client;

  /// Admin-configured support contact channels. Public endpoint, so it
  /// resolves even before auth. Returns empty strings when unset — callers
  /// fall back to the bundled defaults.
  Future<({String email, String whatsapp})> config() async {
    final r = await _client.get('/api/support/config');
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return (
      email: (d['email'] ?? '').toString(),
      whatsapp: (d['whatsapp'] ?? '').toString(),
    );
  }

  Future<List<FaqEntry>> faqs() async {
    final r = await _client.get('/api/faqs');
    final raw = r is Map ? (r['data'] ?? r['faqs'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FaqEntry.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<String> submitTicket(SupportTicketDraft draft) async {
    final r = await _client.post(
      '/api/support',
      body: {
        'subject': draft.subject,
        // Laravel's column is `body`; priority/screenshot have no columns
        // yet, so they ride along inside the body text.
        'body': [
          draft.message,
          if (draft.priority != 'NORMAL') '\n[Priority: ${draft.priority}]',
          if (draft.screenshot != null) '\n[Screenshot: ${draft.screenshot}]',
        ].join(),
      },
    );
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return (d['id'] ?? '').toString();
  }
}
