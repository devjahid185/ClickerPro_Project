// lib/features/auth/data/team_invite_repository_impl.dart

import '../domain/team_invite_repository.dart';
import 'team_invite_api.dart';

class TeamInviteRepositoryImpl implements TeamInviteRepository {
  TeamInviteRepositoryImpl(this._api);

  final TeamInviteApi _api;

  @override
  Future<TeamInviteHandle> generateInvite() async {
    final r = await _api.generateInvite();
    return TeamInviteHandle(code: r.code, expiresAt: r.expiresAt);
  }
}
