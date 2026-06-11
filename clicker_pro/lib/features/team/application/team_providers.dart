import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/team_api.dart';
import '../data/team_repository_impl.dart';
import '../domain/team_member.dart';
import '../domain/team_repository.dart';

final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.read(apiClientProvider)),
);

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepositoryImpl(api: ref.read(teamApiProvider)),
);

final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) {
  ref.watch(teamRefreshProvider);
  return ref.read(teamRepositoryProvider).members();
});

/// Email invites addressed to the logged-in user (accept / decline).
final pendingTeamInvitesProvider = FutureProvider<List<PendingTeamInvite>>((
  ref,
) {
  ref.watch(teamRefreshProvider);
  return ref.read(teamRepositoryProvider).pendingInvites();
});

final teamRefreshProvider = StateProvider<int>((ref) => 0);

final teamControllerProvider =
    NotifierProvider<TeamController, AsyncValue<void>>(TeamController.new);

class TeamController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<({String code, DateTime expiresAt})> generateInviteCode() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref
          .read(teamRepositoryProvider)
          .generateInviteCode();
      state = const AsyncValue.data(null);
      ref.invalidate(teamMembersProvider);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removeMember(String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(teamRepositoryProvider).removeMember(userId);
      state = const AsyncValue.data(null);
      ref.invalidate(teamMembersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> joinWithCode(String code) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(teamRepositoryProvider).joinWithCode(code);
      state = const AsyncValue.data(null);
      ref.invalidate(teamMembersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> inviteByEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(teamRepositoryProvider).inviteByEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> respondInvite(String inviteId, {required bool accept}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(teamRepositoryProvider)
          .respondInvite(inviteId, accept: accept);
      state = const AsyncValue.data(null);
      ref.invalidate(pendingTeamInvitesProvider);
      ref.invalidate(teamMembersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void refresh() {
    ref.invalidate(teamMembersProvider);
    ref.invalidate(pendingTeamInvitesProvider);
  }
}
