// lib/features/team/domain/team_member.dart
//
// A single team membership row.  Backend response from
// `GET /api/team/members`:
//   { members: [{ id, userId, ownerId, role, joinedAt,
//     user: { id, fullName, email, phone, role, avatarUrl } }] }

class TeamMember {
  final String membershipId;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // wire format: uppercase ('MANAGER', 'FREELANCER', …)
  final String? avatarUrl;

  const TeamMember({
    required this.membershipId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final user =
        (json['user'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return TeamMember(
      membershipId: (json['id'] ?? '').toString(),
      userId: (user['id'] ?? json['userId'] ?? '').toString(),
      fullName: (user['fullName'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      phone: user['phone'] as String?,
      role: (user['role'] ?? json['role'] ?? '').toString().toUpperCase(),
      avatarUrl: user['avatarUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamMember && membershipId == other.membershipId);

  @override
  int get hashCode => membershipId.hashCode;
}
