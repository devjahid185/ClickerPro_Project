// lib/features/notifications/application/notification_providers.dart
//
// Riverpod wiring for the notifications inbox।  Three layers:
//
//   1. API + Repository providers — thin construction over `apiClientProvider`।
//   2. Inbox controller            — `AsyncNotifier` holding the live list
//      with optimistic mark-as-read।
//   3. Unread count                — derived `Provider<int>` so any badge
//      (e.g., on the dashboard's bell icon) can `watch` it cheaply।

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/notification_api.dart';
import '../data/notification_repository_impl.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

// ─── 1. API + Repository ──────────────────────────────────────────────

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.read(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(api: ref.read(notificationApiProvider)),
);

// ─── 2. Inbox controller ──────────────────────────────────────────────

class NotificationInboxController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    return ref.read(notificationRepositoryProvider).list();
  }

  /// Pull-to-refresh / explicit refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).list(),
    );
  }

  /// Optimistically flips the row's `read` flag and fires the PATCH।
  /// On failure we restore the previous state and surface the error so
  /// the UI can show a SnackBar; the next `refresh()` will reconcile।
  Future<void> markRead(String id) async {
    final current = state.valueOrNull ?? const <AppNotification>[];
    final idx = current.indexWhere((n) => n.id == id);
    if (idx == -1) return; // unknown id — no-op
    if (current[idx].read) return; // already read

    // Optimistic write
    final next = [...current];
    next[idx] = current[idx].copyWith(read: true);
    state = AsyncData(next);

    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
    } catch (e, st) {
      // Rollback
      state = AsyncData(current);
      // Surface as AsyncError so the UI's error listener can react
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final notificationInboxControllerProvider =
    AsyncNotifierProvider<NotificationInboxController, List<AppNotification>>(
      NotificationInboxController.new,
    );

// ─── 3. Derived: unread count (for top-bar badge) ────────────────────

final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationInboxControllerProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
