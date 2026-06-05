// lib/features/team/domain/team_repository.dart

import 'team_member.dart';

abstract class TeamRepository {
  /// `GET /api/team/members` — own studio's current members.
  Future<List<TeamMember>> members();

  /// `POST /api/team/invite` — generate a 6-digit invite code.
  /// Returns `{ code, expiresAt }`.
  Future<({String code, DateTime expiresAt})> generateInviteCode();

  /// `DELETE /api/team/members/:userId` — remove a member.
  Future<void> removeMember(String userId);
}
