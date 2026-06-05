// lib/features/audit/data/audit_repository_impl.dart
//
// Repository implementation for audit log — coordinates API calls
// and local caching when available.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/audit_log.dart';
import 'audit_api.dart';

final auditRepositoryProvider = Provider<AuditRepositoryImpl>((ref) {
  return AuditRepositoryImpl(ref.read(auditApiProvider));
});

class AuditRepositoryImpl {
  final AuditApi _api;

  AuditRepositoryImpl(this._api);

  Future<void> logEntry(AuditLogEntry entry) async {
    await _api.createEntry(entry);
  }

  Future<List<AuditLogEntry>> getEntries({
    AuditAction? action,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    return _api.fetchEntries(
      action: action,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }
}
