// lib/features/legal/data/legal_api.dart

import '../../../core/network/api_client.dart';

class LegalApi {
  LegalApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getPrivacy(String langCode) async {
    final r =
        await _client.get(
              '/api/legal/privacy',
              query: {'lang': langCode},
              authenticated: false,
            )
            as Map<String, dynamic>;
    return r;
  }

  Future<Map<String, dynamic>> getTerms(String langCode) async {
    final r =
        await _client.get(
              '/api/legal/terms',
              query: {'lang': langCode},
              authenticated: false,
            )
            as Map<String, dynamic>;
    return r;
  }

  Future<void> recordConsent({required String version}) async {
    await _client.post('/api/legal/consent', body: {'version': version});
  }
}
