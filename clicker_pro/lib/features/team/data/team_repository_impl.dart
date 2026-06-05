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
}
