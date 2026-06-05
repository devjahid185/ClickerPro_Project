// lib/features/team/data/team_api.dart

import '../../../core/network/api_client.dart';
import '../domain/team_member.dart';

class TeamApi {
  TeamApi(this._client);

  final ApiClient _client;

  Future<List<TeamMember>> members() async {
    final r = await _client.get('/api/team/members') as Map<String, dynamic>;
    final raw = (r['members'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(TeamMember.fromJson)
        .toList(growable: false);
  }

  Future<({String code, DateTime expiresAt})> generateInviteCode() async {
    final r = await _client.post('/api/team/invite') as Map<String, dynamic>;
    return (
      code: (r['code'] ?? '').toString(),
      expiresAt: DateTime.parse(r['expiresAt'].toString()),
    );
  }

  Future<void> removeMember(String userId) async {
    await _client.delete('/api/team/members/$userId');
  }
}
