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

  /// `GET /api/team/members/{userId}/profile` — limited member profile
  /// (name, photo, phone, gear, finance) for the team owner.
  Future<TeamMemberProfile> memberProfile(String userId) async {
    final r = await _client.get('/api/team/members/$userId/profile');
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return TeamMemberProfile.fromJson(d);
  }

  /// `POST /api/team/join` — existing user redeems a 6-digit passcode.
  Future<void> joinWithCode(String code) async {
    await _client.post('/api/team/join', body: {'code': code});
  }

  /// `POST /api/team/invite-email` — invite a registered user by email.
  Future<void> inviteByEmail(String email) async {
    await _client.post('/api/team/invite-email', body: {'email': email});
  }

  /// `GET /api/team/invites/pending` — invites addressed to me.
  Future<List<PendingTeamInvite>> pendingInvites() async {
    final r = await _client.get('/api/team/invites/pending');
    final raw = r is Map ? (r['data'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PendingTeamInvite.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/team/invites/{id}/respond` — accept or decline.
  Future<void> respondInvite(String inviteId, {required bool accept}) async {
    await _client.post(
      '/api/team/invites/$inviteId/respond',
      body: {'accept': accept},
    );
  }
}

/// A pending email invite shown to the invitee (accept / decline).
class PendingTeamInvite {
  const PendingTeamInvite({
    required this.id,
    required this.ownerName,
    this.ownerEmail,
    this.expiresAt,
  });

  final String id;
  final String ownerName;
  final String? ownerEmail;
  final DateTime? expiresAt;

  factory PendingTeamInvite.fromJson(Map<String, dynamic> j) =>
      PendingTeamInvite(
        id: (j['id'] ?? '').toString(),
        ownerName: (j['ownerName'] ?? 'Studio owner').toString(),
        ownerEmail: j['ownerEmail'] as String?,
        expiresAt: DateTime.tryParse((j['expiresAt'] ?? '').toString()),
      );
}

/// Limited member profile — exactly the fields an owner may see.
class TeamMemberProfile {
  const TeamMemberProfile({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    required this.role,
    this.gear = const [],
    this.financeEvents = 0,
    this.financeEarned = 0,
    this.financePaid = 0,
    this.financeDue = 0,
  });

  final String id;
  final String name;
  final String? phone;
  final String? avatar;
  final String role;
  final List<({String name, String? category, String? condition})> gear;
  final int financeEvents;
  final double financeEarned;
  final double financePaid;
  final double financeDue;

  factory TeamMemberProfile.fromJson(Map<String, dynamic> j) {
    final fin = (j['finance'] as Map?)?.cast<String, dynamic>() ?? const {};
    final gearRaw = (j['gear'] as List?) ?? const [];
    return TeamMemberProfile(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      phone: j['phone'] as String?,
      avatar: j['avatar'] as String?,
      role: (j['role'] ?? '').toString(),
      gear: gearRaw
          .whereType<Map>()
          .map(
            (g) => (
              name: (g['name'] ?? '').toString(),
              category: g['category'] as String?,
              condition: g['condition'] as String?,
            ),
          )
          .toList(growable: false),
      financeEvents: (fin['events'] as num?)?.toInt() ?? 0,
      financeEarned: (fin['earned'] as num?)?.toDouble() ?? 0,
      financePaid: (fin['paid'] as num?)?.toDouble() ?? 0,
      financeDue: (fin['due'] as num?)?.toDouble() ?? 0,
    );
  }
}
