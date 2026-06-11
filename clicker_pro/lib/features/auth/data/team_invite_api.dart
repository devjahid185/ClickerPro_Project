// lib/features/auth/data/team_invite_api.dart

import '../../../core/network/api_client.dart';

class TeamInviteApi {
  TeamInviteApi(this._client);

  final ApiClient _client;

  Future<({String code, DateTime expiresAt})> generateInvite() async {
    // Laravel wraps the invite in {data:{code, expires_at}}.
    final r = await _client.post('/api/team/invite');
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : (r is Map ? r.cast<String, dynamic>() : <String, dynamic>{});
    final expiresRaw = (d['expires_at'] ?? d['expiresAt'] ?? '').toString();
    return (
      code: (d['code'] ?? '').toString(),
      expiresAt:
          DateTime.tryParse(expiresRaw) ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }
}
