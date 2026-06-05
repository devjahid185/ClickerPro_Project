// lib/features/auth/data/team_invite_api.dart

import '../../../core/network/api_client.dart';

class TeamInviteApi {
  TeamInviteApi(this._client);

  final ApiClient _client;

  Future<({String code, DateTime expiresAt})> generateInvite() async {
    final r = await _client.post('/api/team/invite') as Map<String, dynamic>;
    return (
      code: r['code'] as String,
      expiresAt: DateTime.parse(r['expiresAt'] as String),
    );
  }
}
