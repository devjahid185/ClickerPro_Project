// lib/features/team/domain/team_repository.dart

import '../data/team_api.dart' show PendingTeamInvite;
import 'team_member.dart';

abstract class TeamRepository {
  /// `GET /api/team/members` — own studio's current members.
  Future<List<TeamMember>> members();

  /// `POST /api/team/invite` — generate a 6-digit invite code.
  /// Returns `{ code, expiresAt }`.
  Future<({String code, DateTime expiresAt})> generateInviteCode();

  /// `DELETE /api/team/members/:userId` — remove a member.
  Future<void> removeMember(String userId);

  /// `POST /api/team/join` — join a team with a 6-digit passcode.
  Future<void> joinWithCode(String code);

  /// `POST /api/team/invite-email` — invite a registered user by email.
  Future<void> inviteByEmail(String email);

  /// `GET /api/team/invites/pending` — email invites waiting for me.
  Future<List<PendingTeamInvite>> pendingInvites();

  /// `POST /api/team/invites/{id}/respond` — accept or decline an invite.
  Future<void> respondInvite(String inviteId, {required bool accept});
}
