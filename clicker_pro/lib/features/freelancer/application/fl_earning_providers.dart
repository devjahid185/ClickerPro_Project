// lib/features/freelancer/application/fl_earning_providers.dart
//
// Riverpod wiring for the freelancer earnings feature.  Two layers:
//
//   1. API + Repository providers — thin construction over `apiClientProvider`.
//   2. Overview controller        — `AsyncNotifier` that owns the live data.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/fl_earning_api.dart';
import '../data/fl_earning_repository_impl.dart';
import '../domain/fl_earning.dart';
import '../domain/fl_earning_repository.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final flEarningApiProvider = Provider<FlEarningApi>(
  (ref) => FlEarningApi(ref.read(apiClientProvider)),
);

final flEarningRepositoryProvider = Provider<FlEarningRepository>(
  (ref) => FlEarningRepositoryImpl(api: ref.read(flEarningApiProvider)),
);

// ─── 2. Overview controller ───────────────────────────────────────────

class FlEarningOverviewController extends AsyncNotifier<FlEarningsOverview> {
  @override
  Future<FlEarningsOverview> build() async {
    return ref.read(flEarningRepositoryProvider).overview();
  }

  /// Pull-to-refresh handler.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(flEarningRepositoryProvider).overview(),
    );
  }
}

final flEarningOverviewControllerProvider =
    AsyncNotifierProvider<FlEarningOverviewController, FlEarningsOverview>(
      FlEarningOverviewController.new,
    );

// ─── 3. Event → owner (company) name lookup ───────────────────────────
//
// The freelancer booking list shows the studio/company name in place of the
// client. The earnings overview already carries a per-event owner name (for
// unpaid events), so we expose a keyed lookup instead of a new endpoint.
// Returns null when the event isn't in the overview yet — the caller then
// shows a neutral fallback.
final flEventOwnerNameProvider = Provider.family<String?, String>((ref, eventId) {
  final overview = ref.watch(flEarningOverviewControllerProvider).valueOrNull;
  if (overview == null) return null;
  for (final e in overview.pendingEvents) {
    if (e.eventId == eventId) {
      return e.ownerName.trim().isEmpty ? null : e.ownerName;
    }
  }
  return null;
});
