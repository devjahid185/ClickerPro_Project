import '../domain/team_member.dart';
import '../domain/team_repository.dart';
import 'team_api.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl({required TeamApi api}) : _api = api;

  final TeamApi _api;

  @override
  Future<List<TeamMember>> members() => _api.members();

  @override
  Future<({String code, DateTime expiresAt})> generateInviteCode() =>
      _api.generateInviteCode();

  @override
  Future<void> removeMember(String userId) => _api.removeMember(userId);

  @override
  Future<void> joinWithCode(String code) => _api.joinWithCode(code);

  @override
  Future<void> inviteByEmail(String email) => _api.inviteByEmail(email);

  @override
  Future<List<PendingTeamInvite>> pendingInvites() => _api.pendingInvites();

  @override
  Future<void> respondInvite(String inviteId, {required bool accept}) =>
      _api.respondInvite(inviteId, accept: accept);
}
