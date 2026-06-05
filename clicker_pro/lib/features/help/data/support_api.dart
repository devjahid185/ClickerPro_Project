// lib/features/help/data/support_api.dart

import '../../../core/network/api_client.dart';
import '../domain/faq_entry.dart';
import '../domain/support_ticket_draft.dart';

class SupportApi {
  SupportApi(this._client);

  final ApiClient _client;

  Future<List<FaqEntry>> faqs() async {
    final r =
        await _client.get('/api/support/faqs', authenticated: false)
            as Map<String, dynamic>;
    final raw = (r['faqs'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(FaqEntry.fromJson)
        .toList(growable: false);
  }

  Future<String> submitTicket(SupportTicketDraft draft) async {
    final r =
        await _client.post('/api/support/ticket', body: draft.toJson())
            as Map<String, dynamic>;
    final t = (r['ticket'] as Map?)?.cast<String, dynamic>();
    return (t?['id'] ?? '').toString();
  }
}
