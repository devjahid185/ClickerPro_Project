import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/staff_payout_store.dart';
import '../data/team_api.dart';
import '../data/team_repository_impl.dart';
import '../domain/staff_payout.dart';
import '../domain/team_member.dart';
import '../domain/team_repository.dart';

final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.read(apiClientProvider)),
);

final staffPayoutStoreProvider = Provider<StaffPayoutStore>(
  (ref) => StaffPayoutStore(),
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

/// Owner-side staff payout sheet (assignment earnings per team member).
///
/// Offline-first: fetch from the server and cache it, but if the backend is
/// unreachable fall back to the cached sheet. Either way, locally-recorded
/// "paid" overrides are layered on top so settled payouts persist offline.
final staffPayoutsProvider = FutureProvider<StaffPayoutSheet>((ref) async {
  ref.watch(teamRefreshProvider);
  final store = ref.read(staffPayoutStoreProvider);
  final localPaid = await store.readLocalPaid();
  try {
    final sheet = await ref.read(teamApiProvider).payouts();
    await store.cacheSheet(sheet);
    return store.applyLocalPaid(sheet, localPaid);
  } catch (_) {
    final cached = await store.readCachedSheet();
    if (cached == null) rethrow;
    return store.applyLocalPaid(cached, localPaid);
  }
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

  /// Settle a member's payout — one event ([assignmentId] set) or all of
  /// their outstanding payouts (omitted) — then refresh the sheet.
  ///
  /// Offline-first: if the server can't be reached, record the settlement
  /// locally (per-assignment) so the payout still shows as PAID and the due
  /// total drops. The override is replayed by [staffPayoutsProvider] until
  /// the backend confirms it. This is what previously made "Pay" silently
  /// fail with the backend offline.
  Future<void> markPayoutPaid(String userId, {String? assignmentId}) async {
    state = const AsyncValue.loading();
    final store = ref.read(staffPayoutStoreProvider);
    try {
      await ref
          .read(teamApiProvider)
          .markPayoutPaid(userId, assignmentId: assignmentId);
      state = const AsyncValue.data(null);
      ref.invalidate(staffPayoutsProvider);
    } catch (_) {
      // Backend unreachable — settle locally so the owner's action sticks.
      final ids = _assignmentIdsToSettle(userId, assignmentId);
      if (ids.isEmpty) {
        // Nothing we can record offline (no cached sheet yet) — surface it.
        state = const AsyncValue.data(null);
        ref.invalidate(staffPayoutsProvider);
        return;
      }
      await store.addLocalPaid(ids);
      state = const AsyncValue.data(null);
      ref.invalidate(staffPayoutsProvider);
    }
  }

  /// Which assignment ids a settle action covers: just [assignmentId] for a
  /// single event, or every unpaid assignment for the member when paying all.
  List<String> _assignmentIdsToSettle(String userId, String? assignmentId) {
    if (assignmentId != null && assignmentId.isNotEmpty) return [assignmentId];
    final sheet = ref.read(staffPayoutsProvider).valueOrNull;
    final member = sheet?.members.where((m) => m.userId == userId).firstOrNull;
    if (member == null) return const [];
    return member.items
        .where((it) => !it.paid && it.assignmentId.isNotEmpty)
        .map((it) => it.assignmentId)
        .toList(growable: false);
  }

  void refresh() {
    ref.invalidate(teamMembersProvider);
    ref.invalidate(pendingTeamInvitesProvider);
    ref.invalidate(staffPayoutsProvider);
  }
}
