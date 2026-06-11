// lib/features/legal/data/legal_api.dart
//
// Legal-content endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + LegalController):
//   GET /api/legal/privacy/{lang} → { data: { lang, content } }
//   GET /api/legal/terms/{lang}   → { data: { lang, content } }
// (lang is a PATH parameter, not a query string.)

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';

class LegalApi {
  LegalApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _data(dynamic r) {
    if (r is! Map) return <String, dynamic>{};
    final d = r['data'];
    return (d is Map ? d : r).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getPrivacy(String langCode) async {
    final r = await _client.get(
      '/api/legal/privacy/$langCode',
      authenticated: false,
    );
    return _data(r);
  }

  Future<Map<String, dynamic>> getTerms(String langCode) async {
    final r = await _client.get(
      '/api/legal/terms/$langCode',
      authenticated: false,
    );
    return _data(r);
  }

  /// Consent bookkeeping. The backend has no consent endpoint yet — the
  /// attempt is fire-and-forget so accepting the terms never blocks the
  /// user on a 404.
  Future<void> recordConsent({required String version}) async {
    try {
      await _client.post('/api/legal/consent', body: {'version': version});
    } catch (e) {
      AppLogger.w('legal', 'consent endpoint unavailable: $e');
    }
  }
}
