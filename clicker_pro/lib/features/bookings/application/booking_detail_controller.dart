// lib/features/bookings/application/booking_detail_controller.dart
//
// AsyncNotifier family that backs the booking detail screen. Each
// controller is keyed by the booking's local id and exposes:
//
//   • build(id)       — load the BookingDetailEnvelope from Drift on
//                       first access, then trigger a background remote
//                       refresh so the screen flips from cached to
//                       canonical data without blocking the first frame
//   • refresh()       — manual refresh (pull-to-refresh on the screen)
//   • transitionStatus(to, note?) — delegates to StatusRepository, then
//                       reloads the envelope so the timeline and badge
//                       reflect the new state
//   • cancel(reason)  — shorthand for `transitionStatus(cancelled, reason)`
//
// The controller intentionally does NOT subscribe to a Drift stream —
// the detail envelope is composite (8 entities) so a single-shot reload
// after each mutation is simpler and equally responsive in practice.
// If/when we need finer-grained reactivity we'll layer a per-entity
// watch provider on top.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "BookingDetailController". Validates Requirements 5.1, 5.7, 5.8,
// 3.4–3.11.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/application/session_controller.dart';
import '../../calendar_sync/data/calendar_sync_service.dart';
import '../domain/booking_detail_envelope.dart';
import '../domain/booking_repository.dart';
import 'booking_providers.dart';

class BookingDetailController
    extends FamilyAsyncNotifier<BookingDetailEnvelope, String> {
  @override
  Future<BookingDetailEnvelope> build(String bookingLocalId) async {
    // Local-first: read the envelope from Drift on the very first frame
    // so the screen never shows the LensLoader for cached data.
    final repo = ref.read(bookingRepositoryProvider);
    final envelope = await repo.getDetail(bookingLocalId);

    // Fire-and-forget background refresh from the server. We use the
    // booking's remoteId when available; if the booking has not yet
    // been synced (no remoteId) we skip the network call entirely so
    // the worker can drain the create first.
    final remoteId = envelope.booking.remoteId;
    if (remoteId != null) {
      // Don't await — let the first frame paint the cached envelope.
      // ignore: discarded_futures
      _refreshFromRemote(repo, remoteId);
    }

    return envelope;
  }

  /// Manual refresh — used by the screen's pull-to-refresh affordance.
  /// Re-reads from Drift after the remote pull lands.
  Future<void> refresh() async {
    final current = state.value;
    final remoteId = current?.booking.remoteId;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(bookingRepositoryProvider);
      if (remoteId != null) {
        await repo.refreshFromRemote(singleEventId: remoteId);
      }
      final envelope = await repo.getDetail(arg);
      state = AsyncValue.data(envelope);
    } catch (e, st) {
      AppLogger.e('booking-detail', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Drives a status transition through the repository. The returned
  /// future completes once the local commit lands; the screen rebuilds
  /// against the new envelope so the timeline picks up the pending row.
  Future<void> transitionStatus(BookingStatus to, {String? note}) async {
    final current = state.value;
    if (current == null) return;
    final session = ref.read(sessionControllerProvider).value;
    final user = session?.user;
    if (user == null) {
      throw StateError(
        'Cannot transition status without an authenticated session.',
      );
    }
    final policy = ref.read(bookingsPolicyProvider);

    await ref
        .read(statusRepositoryProvider)
        .transition(
          bookingId: arg,
          expectedFrom: current.booking.status,
          to: to,
          changedByUserId: user.id,
          policy: policy,
          note: note,
        );

    // Re-read the local envelope so the new status + history row land
    // in the screen immediately.
    final envelope = await ref.read(bookingRepositoryProvider).getDetail(arg);
    state = AsyncValue.data(envelope);

    if (to == BookingStatus.confirmed &&
        current.booking.status != BookingStatus.confirmed &&
        await CalendarSyncService.isAutoSyncEnabled()) {
      final booking = envelope.booking;
      final description = [
        if (booking.clientName != null) 'Client: ${booking.clientName}',
        if (booking.clientPhone != null) 'Phone: ${booking.clientPhone}',
        'Booked via GRAPHY7',
      ].join('\n');
      await CalendarSyncService.openGoogleCalendar(
        title: booking.title,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        venue: booking.venue,
        description: description,
        allowWebFallback: false,
        bookingId: booking.id,
      );
    }
  }

  /// Convenience for the cancel flow — the cancel reason is required
  /// to be 1–500 chars per Requirement 3.8; the controller delegates
  /// validation to the dialog and trusts the caller.
  Future<void> cancel(String reason) =>
      transitionStatus(BookingStatus.cancelled, note: reason);

  /// Persists the delivery checklist (a `{itemKey: bool}` map) onto the
  /// booking. We store it inside the booking's existing `clientRequirements`
  /// JSON under `deliveryChecklist`, then route through the normal
  /// `repository.save()` so it commits to Drift and rides the offline outbox
  /// to the server — no separate table or endpoint needed.
  Future<void> updateDeliveryChecklist(Map<String, bool> checklist) async {
    final current = state.value;
    if (current == null) return;
    final policy = ref.read(bookingsPolicyProvider);

    final requirements = <String, dynamic>{
      ...?current.booking.clientRequirements,
      'deliveryChecklist': checklist,
    };
    final updated = current.booking.copyWith(
      clientRequirements: requirements,
    );

    await ref.read(bookingRepositoryProvider).save(updated, policy: policy);

    // Re-read the local envelope so the screen reflects the saved checklist.
    final envelope = await ref.read(bookingRepositoryProvider).getDetail(arg);
    state = AsyncValue.data(envelope);
  }

  /// Saves the Google Drive / gallery link for this booking. Assigned
  /// freelancers and photographers paste the delivery link here once the
  /// shoot is done; it rides the same offline outbox as any other edit.
  Future<void> updateDriveLink(String link) async {
    final current = state.value;
    if (current == null) return;
    final trimmed = link.trim();
    if (trimmed.isEmpty) return;
    final policy = ref.read(bookingsPolicyProvider);

    final updated = current.booking.copyWith(driveLink: trimmed);
    await ref.read(bookingRepositoryProvider).save(updated, policy: policy);

    final envelope = await ref.read(bookingRepositoryProvider).getDetail(arg);
    state = AsyncValue.data(envelope);
  }

  Future<void> _refreshFromRemote(
    BookingRepository repo,
    String remoteId,
  ) async {
    try {
      await repo.refreshFromRemote(singleEventId: remoteId);
      // After a successful refresh, re-read from Drift so the screen
      // reflects any server-side changes.
      final envelope = await repo.getDetail(arg);
      // Only update if we're still the active state — if the user has
      // navigated away the controller is already disposed.
      if (state.hasValue) {
        state = AsyncValue.data(envelope);
      }
    } catch (e, st) {
      // Background refresh failures are non-fatal — the screen keeps
      // rendering the cached envelope. The OfflineBanner shows when
      // applicable.
      AppLogger.w(
        'booking-detail',
        'background refresh failed: ${e.runtimeType}',
      );
      AppLogger.e('booking-detail', e, st);
    }
  }
}

/// Family-keyed by booking local id. Pass the id when watching:
/// `ref.watch(bookingDetailControllerProvider(id))`.
final bookingDetailControllerProvider =
    AsyncNotifierProvider.family<
      BookingDetailController,
      BookingDetailEnvelope,
      String
    >(BookingDetailController.new);

/// Convenience: streams the live status-conflict events from the status
/// repository so the detail screen can listen and surface a SnackBar
/// when the worker reconciles a 409.
final statusConflictStreamProvider = StreamProvider<dynamic>((ref) {
  return ref.read(statusRepositoryProvider).statusConflictStream;
});
