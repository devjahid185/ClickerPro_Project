// lib/features/freelancer/application/fl_tools_providers.dart
//
// Riverpod wiring for the freelancer work-tools feature (FL-05–FL-09).
// Layers:
//
//   1. API + Repository providers — thin construction over `apiClientProvider`.
//   2. Blackout list controller   — AsyncNotifier for blackout dates.
//   3. Leave request controller    — AsyncNotifier for leave requests.
//   4. Work history provider       — FutureProvider, refreshes on demand.
//   5. Dashboard events provider   — FutureProvider for multi-owner view.
//   6. Conflicts provider          — FutureProvider for overlap warnings.
//   7. Check-in controller         — AsyncNotifier for live check-in state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/fl_tools_api.dart';
import '../data/fl_tools_repository_impl.dart';
import '../domain/fl_blackout_date.dart';
import '../domain/fl_checkin.dart';
import '../domain/fl_leave_request.dart';
import '../domain/fl_tools_repository.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final flToolsApiProvider = Provider<FlToolsApi>(
  (ref) => FlToolsApi(ref.read(apiClientProvider)),
);

final flToolsRepositoryProvider = Provider<FlToolsRepository>(
  (ref) => FlToolsRepositoryImpl(api: ref.read(flToolsApiProvider)),
);

// ─── 2. Blackout Dates (FL-05) ───────────────────────────────────────

class FlBlackoutController extends AsyncNotifier<List<FlBlackoutDate>> {
  @override
  Future<List<FlBlackoutDate>> build() async {
    return ref.read(flToolsRepositoryProvider).listBlackouts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(flToolsRepositoryProvider).listBlackouts(),
    );
  }

  Future<FlBlackoutDate> add(FlBlackoutDate draft) async {
    final saved = await ref
        .read(flToolsRepositoryProvider)
        .createBlackout(draft);
    state.whenData((current) {
      state = AsyncData(<FlBlackoutDate>[saved, ...current]);
    });
    return saved;
  }

  Future<void> remove(String id) async {
    await ref.read(flToolsRepositoryProvider).deleteBlackout(id);
    state.whenData((current) {
      state = AsyncData(
        current.where((b) => b.id != id).toList(growable: false),
      );
    });
  }
}

final flBlackoutControllerProvider =
    AsyncNotifierProvider<FlBlackoutController, List<FlBlackoutDate>>(
      FlBlackoutController.new,
    );

// ─── 3. Leave Requests (FL-07) ───────────────────────────────────────

class FlLeaveRequestController extends AsyncNotifier<List<FlLeaveRequest>> {
  @override
  Future<List<FlLeaveRequest>> build() async {
    return ref.read(flToolsRepositoryProvider).listLeaveRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(flToolsRepositoryProvider).listLeaveRequests(),
    );
  }

  Future<FlLeaveRequest> submit(FlLeaveRequest draft) async {
    final saved = await ref
        .read(flToolsRepositoryProvider)
        .createLeaveRequest(draft);
    state.whenData((current) {
      state = AsyncData(<FlLeaveRequest>[saved, ...current]);
    });
    return saved;
  }

  Future<void> cancel(String id) async {
    final updated = await ref
        .read(flToolsRepositoryProvider)
        .cancelLeaveRequest(id);
    state.whenData((current) {
      state = AsyncData([
        for (final r in current)
          if (r.id == id) updated else r,
      ]);
    });
  }
}

final flLeaveRequestControllerProvider =
    AsyncNotifierProvider<FlLeaveRequestController, List<FlLeaveRequest>>(
      FlLeaveRequestController.new,
    );

// ─── 4. Work History (FL-06) ─────────────────────────────────────────

final flWorkHistoryProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(flToolsRepositoryProvider).listWorkHistory(),
);

// ─── 5. Multi-Owner Dashboard Events (FL-08) ─────────────────────────

final flDashboardEventsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(flToolsRepositoryProvider).listAllOwnerEvents(),
);

// ─── 6. Conflict Detector (FL-08) ────────────────────────────────────

final flConflictsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(flToolsRepositoryProvider).listConflicts(),
);

// ─── 7. Check-In Controller (FL-09) ──────────────────────────────────

class FlCheckinController extends AsyncNotifier<FlCheckin?> {
  @override
  Future<FlCheckin?> build() async => null;

  Future<FlCheckin> checkin(FlCheckin draft) async {
    final saved = await ref
        .read(flToolsRepositoryProvider)
        .recordCheckin(draft);
    state = AsyncData(saved);
    return saved;
  }

  Future<void> fetchStatus(String eventId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(flToolsRepositoryProvider).getCheckinStatus(eventId),
    );
  }
}

final flCheckinControllerProvider =
    AsyncNotifierProvider<FlCheckinController, FlCheckin?>(
      FlCheckinController.new,
    );
