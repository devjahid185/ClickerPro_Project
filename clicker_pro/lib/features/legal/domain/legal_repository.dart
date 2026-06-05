// lib/features/legal/domain/legal_repository.dart

class LegalDocument {
  const LegalDocument({required this.version, required this.body});

  final String version;
  final String body;
}

abstract class LegalRepository {
  Future<LegalDocument> getPrivacy(String langCode);
  Future<LegalDocument> getTerms(String langCode);
  Future<void> recordConsent({required String version});
  Future<String> requestDataExport();
}
