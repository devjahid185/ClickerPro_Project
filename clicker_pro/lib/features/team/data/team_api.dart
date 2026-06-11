// lib/features/team/data/team_api.dart
//
// Team endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + TeamController):
//   GET    /api/team/members              → { data: [user…] }  (flat user rows)
//   POST   /api/team/invite               → { data: {code, expires_at} } (201)
//   DELETE /api/team/members/:userId      → { message: ok }

import '../../../core/network/api_client.dart';
import '../domain/team_member.dart';

class TeamApi {
  TeamApi(this._client);

  final ApiClient _client;

  /// Laravel returns the member USERS directly (no membership wrapper) in
  /// snake_case — adapt to the local [TeamMember] shape.
  TeamMember _fromServer(Map<String, dynamic> j) => TeamMember(
    membershipId: (j['id'] ?? '').toString(),
    userId: (j['id'] ?? '').toString(),
    fullName: (j['name'] ?? j['fullName'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    phone: j['phone'] as String?,
    role: (j['role'] ?? '').toString().toUpperCase(),
    avatarUrl: (j['avatar'] ?? j['avatarUrl']) as String?,
  );

  Future<List<TeamMember>> members() async {
    final r = await _client.get('/api/team/members');
    final raw = r is Map ? (r['data'] ?? r['members'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => _fromServer(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<({String code, DateTime expiresAt})> generateInviteCode() async {
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

  Future<void> removeMember(String userId) async {
    await _client.delete('/api/team/members/$userId');
  }
}
