// lib/features/legal/data/legal_repository_impl.dart

import '../../auth/data/auth_api.dart';
import '../domain/legal_repository.dart';
import 'legal_api.dart';

class LegalRepositoryImpl implements LegalRepository {
  LegalRepositoryImpl({required LegalApi api, required AuthApi authApi})
    : _api = api,
      _auth = authApi;

  final LegalApi _api;
  final AuthApi _auth;
  final Map<String, LegalDocument> _privacyCache = {};
  final Map<String, LegalDocument> _termsCache = {};

  @override
  Future<LegalDocument> getPrivacy(String langCode) async {
    final cached = _privacyCache[langCode];
    if (cached != null) return cached;
    final r = await _api.getPrivacy(langCode);
    final doc = LegalDocument(
      version: r['version'] as String,
      body: r['body'] as String,
    );
    _privacyCache[langCode] = doc;
    return doc;
  }

  @override
  Future<LegalDocument> getTerms(String langCode) async {
    final cached = _termsCache[langCode];
    if (cached != null) return cached;
    final r = await _api.getTerms(langCode);
    final doc = LegalDocument(
      version: r['version'] as String,
      body: r['body'] as String,
    );
    _termsCache[langCode] = doc;
    return doc;
  }

  @override
  Future<void> recordConsent({required String version}) =>
      _api.recordConsent(version: version);

  @override
  Future<String> requestDataExport() => _auth.requestDataExport();
}
