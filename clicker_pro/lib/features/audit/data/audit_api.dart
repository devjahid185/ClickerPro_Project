import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../domain/audit_log.dart';

final auditApiProvider = Provider<AuditApi>(
  (ref) => AuditApi(ref.read(apiClientProvider)),
);

class AuditApi {
  AuditApi(this._client);
  final ApiClient _client;

  Future<void> createEntry(AuditLogEntry entry) async {
    await _client.post(
      '/api/audit-logs',
      body: <String, dynamic>{
        'actorName':   entry.actorName,
        'action':      entry.action.name.toUpperCase(),
        'entityType':  entry.entityType,
        'entityId':    entry.entityId,
        if (entry.entityLabel != null) 'entityLabel': entry.entityLabel,
        if (entry.before != null) 'before': entry.before,
        if (entry.after  != null) 'after':  entry.after,
      },
    );
  }

  Future<List<AuditLogEntry>> fetchEntries({
    AuditAction? action,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit':  '$limit',
      'offset': '$offset',
      if (action != null) 'action': action.name.toUpperCase(),
      if (from   != null) 'from':   from.toIso8601String(),
      if (to     != null) 'to':     to.toIso8601String(),
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final r = await _client.get('/api/audit-logs?$query') as Map<String, dynamic>;
    final rows = r['data'] as List? ?? const [];
    return rows
        .map((e) => AuditLogEntry.fromJson(_normalize(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> _normalize(Object? raw) {
    final m = (raw as Map).cast<String, dynamic>();
    final action = m['action'];
    return <String, dynamic>{
      ...m,
      if (action is String) 'action': action.toLowerCase(),
    };
  }
}
