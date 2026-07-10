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
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking_filter.dart';
import '../data/local_notifications_builder.dart';
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
  Future<List<AppNotification>> build() => _load();

  /// Pull-to-refresh / explicit refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Local-first load: derive notifications from the on-device booking list
  /// (works fully offline), then merge in the server inbox when reachable.
  /// The inbox never shows empty/error just because the backend is down —
  /// mirrors the local-first search fix.
  Future<List<AppNotification>> _load() async {
    final local = await _localNotifications();

    List<AppNotification> server = const [];
    try {
      server = await ref.read(notificationRepositoryProvider).list();
    } catch (_) {
      // Backend unreachable/undeployed — fall back to local-only so the
      // bell still shows the user's upcoming shoots.
    }

    return _merge(local, server);
  }

  Future<List<AppNotification>> _localNotifications() async {
    try {
      final bookings = await ref.read(
        bookingListAllProvider(const BookingFilter()).future,
      );
      return LocalNotificationsBuilder.fromBookings(bookings);
    } catch (_) {
      return const [];
    }
  }

  /// Server rows win over locally-derived ones for the same booking (the
  /// backend copy carries the authoritative read-state + id). Everything is
  /// sorted newest-first.
  List<AppNotification> _merge(
    List<AppNotification> local,
    List<AppNotification> server,
  ) {
    // A server notification deeplinking to /bookings/<id> supersedes the
    // local reminder for that same booking.
    final serverBookingIds = <String>{
      for (final n in server)
        if (_bookingIdOf(n.deeplink) != null) _bookingIdOf(n.deeplink)!,
    };

    final merged = <AppNotification>[
      ...server,
      ...local.where(
        (n) => !serverBookingIds.contains(_bookingIdOf(n.deeplink)),
      ),
    ]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return merged;
  }

  /// Extracts the booking id from a `/bookings/<id>` deeplink, else null.
  String? _bookingIdOf(String? deeplink) {
    if (deeplink == null) return null;
    final segments = deeplink.split('?').first.split('#').first.split('/')
      ..removeWhere((s) => s.isEmpty);
    if (segments.length >= 2 && segments.first == 'bookings') {
      return segments[1];
    }
    return null;
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
