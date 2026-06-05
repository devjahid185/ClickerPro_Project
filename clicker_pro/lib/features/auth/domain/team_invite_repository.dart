// lib/features/auth/domain/team_invite_repository.dart

class TeamInviteHandle {
  const TeamInviteHandle({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

abstract class TeamInviteRepository {
  /// Owner / Both only. Returns a 6-digit code valid for 24h.
  Future<TeamInviteHandle> generateInvite();
}
