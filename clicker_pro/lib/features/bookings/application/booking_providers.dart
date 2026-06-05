// lib/features/bookings/application/booking_providers.dart
//
// Bookings module — Riverpod provider tree.
//
// Splits cleanly into three layers:
//
//   1. API providers          — thin construction over `apiClientProvider`.
//   2. Repository providers   — wire DAOs + APIs into the domain contracts.
//   3. UI-state providers     — filter / search / page cursor.
//   4. Watch providers        — Drift-backed streams keyed by filter+page.
//   5. Outbox dispatcher + worker.
//
// Kept in the bookings feature folder (rather than `core/providers.dart`)
// so the booking surface remains self-contained and test overrides only
// need to import a single file.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/sync/bookings_outbox_dispatcher.dart';
import '../../../core/sync/outbox_worker.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/user_role.dart';
import '../../profile/application/profile_controllers.dart';
import '../data/assignment_api.dart';
import '../data/assignment_repository_impl.dart';
import '../data/booking_api.dart';
import '../data/booking_repository_impl.dart';
import '../data/client_api.dart';
import '../data/client_repository_impl.dart';
import '../data/package_api.dart';
import '../data/package_repository_impl.dart';
import '../data/payment_api.dart';
import '../data/payment_repository_impl.dart';
import '../data/re_edit_api.dart';
import '../data/re_edit_repository_impl.dart';
import '../data/status_repository_impl.dart';
import '../data/task_progress_api.dart';
import '../data/task_progress_repository_impl.dart';
import '../domain/assignment_repository.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/booking_repository.dart';
import '../domain/client.dart';
import '../domain/client_repository.dart';
import '../domain/package.dart';
import '../domain/package_repository.dart';
import '../domain/payment_repository.dart';
import '../domain/re_edit_repository.dart';
import '../domain/status_repository.dart';
import '../domain/task_progress_repository.dart';

// ---------------------------------------------------------------------------
// 1. API providers
// ---------------------------------------------------------------------------

final bookingApiProvider = Provider<BookingApi>(
  (ref) => BookingApi(ref.read(apiClientProvider)),
);

final clientApiProvider = Provider<ClientApi>(
  (ref) => ClientApi(ref.read(apiClientProvider)),
);

final assignmentApiProvider = Provider<AssignmentApi>(
  (ref) => AssignmentApi(ref.read(apiClientProvider)),
);

final paymentApiProvider = Provider<PaymentApi>(
  (ref) => PaymentApi(ref.read(apiClientProvider)),
);

final packageApiProvider = Provider<PackageApi>(
  (ref) => PackageApi(ref.read(apiClientProvider)),
);

final reEditApiProvider = Provider<ReEditApi>(
  (ref) => ReEditApi(ref.read(apiClientProvider)),
);

final taskProgressApiProvider = Provider<TaskProgressApi>(
  (ref) => TaskProgressApi(ref.read(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// 2. Repository providers
// ---------------------------------------------------------------------------

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(
    api: ref.read(bookingApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final clientRepositoryProvider = Provider<ClientRepository>(
  (ref) => ClientRepositoryImpl(
    api: ref.read(clientApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => AssignmentRepositoryImpl(
    api: ref.read(assignmentApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(
    api: ref.read(paymentApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final packageRepositoryProvider = Provider<PackageRepository>(
  (ref) => PackageRepositoryImpl(
    api: ref.read(packageApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  final impl = StatusRepositoryImpl(
    api: ref.read(bookingApiProvider),
    db: ref.read(appDatabaseProvider),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

final reEditRepositoryProvider = Provider<ReEditRepository>(
  (ref) => ReEditRepositoryImpl(
    api: ref.read(reEditApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final taskProgressRepositoryProvider = Provider<TaskProgressRepository>(
  (ref) => TaskProgressRepositoryImpl(
    api: ref.read(taskProgressApiProvider),
    db: ref.read(appDatabaseProvider),
    currentUserId: ref.watch(currentUserProvider).value?.id ?? '',
  ),
);

// ---------------------------------------------------------------------------
// 3. UI-state providers
// ---------------------------------------------------------------------------

/// Active filter applied to the booking list. UI writes through on every
/// filter-control change; the value is the family key for the watch
/// providers below so equality must be value-based (handled by
/// `BookingFilter.==`).
final bookingFilterProvider = StateProvider<BookingFilter>(
  (ref) => const BookingFilter(),
);

/// 0-based page cursor for infinite-scroll pagination. Resets to 0 on
/// any filter change (handled by the list controller in a later wave —
/// for now the screen reads directly).
final bookingListPageProvider = StateProvider<int>((ref) => 0);

/// Current free-text search string. Independent from `BookingFilter` so
/// debounce can apply at the controller level without re-keying the
/// filter family on every keystroke.
final bookingSearchProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// 4. Watch providers
// ---------------------------------------------------------------------------

/// Stream of bookings for the active filter + page, with role scope
/// applied. Keyed by `BookingFilter` so different filter combinations
/// each get their own cached stream.
///
/// Falls back to an empty stream while no user is loaded (e.g. during
/// app boot) so the screen renders an `EmptyState` rather than crashing
/// on a null currentUserId.
final bookingListProvider = StreamProvider.family<List<Booking>, BookingFilter>(
  (ref, filter) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Stream<List<Booking>>.empty();
    final policy = ref.watch(rolePolicyProvider);
    final page = ref.watch(bookingListPageProvider);
    return ref
        .read(bookingRepositoryProvider)
        .watchList(filter, policy: policy, currentUserId: user.id, page: page);
  },
);

/// Convenience: returns the `currentUserId` or `null` when the session is
/// unauthenticated. Centralized so screens / controllers don't repeat the
/// AsyncValue unwrapping logic.
final bookingsCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).value?.id;
});

/// Convenience: returns the active `RolePolicy`. Defaults to an Owner
/// policy while loading — same behaviour as `rolePolicyProvider` so
/// capability gates don't flicker.
final bookingsPolicyProvider = Provider<RolePolicy>((ref) {
  final session = ref.watch(sessionControllerProvider).value;
  return RolePolicy(session?.user.role ?? UserRole.owner);
});

/// Watches a single client by local id. Used by the booking list row to
/// resolve `Booking.clientId` → display name without joining at the DAO
/// layer. Family-keyed by client id so concurrent rows share the same
/// underlying stream when they reference the same client.
final clientByIdProvider = StreamProvider.family<Client?, String>(
  (ref, clientId) => ref.read(clientRepositoryProvider).watch(clientId),
);

/// Watches the studio's packages list. Used by the booking edit
/// screen's package picker. Cached by Riverpod so repeated picker opens
/// don't re-query Drift on every mount.
final packagesProvider = StreamProvider<List<Package>>(
  (ref) => ref.read(packageRepositoryProvider).watchAll(),
);

/// `(year, month)` cursor for the calendar screen. Defaults to the
/// current calendar month at first read.
final calendarMonthProvider = StateProvider<({int year, int month})>((ref) {
  final now = DateTime.now();
  return (year: now.year, month: now.month);
});

/// Streams the bookings whose `date` falls inside the visible month.
/// Family-keyed by the (year, month) tuple via a small record so two
/// distinct months don't share state.
final calendarBookingsProvider =
    StreamProvider.family<List<Booking>, ({int year, int month})>((ref, key) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return const Stream<List<Booking>>.empty();
      final policy = ref.watch(rolePolicyProvider);
      return ref
          .read(bookingRepositoryProvider)
          .watchMonth(
            key.year,
            key.month,
            policy: policy,
            currentUserId: user.id,
          );
    });

// ---------------------------------------------------------------------------
// 5. Outbox dispatcher + worker
// ---------------------------------------------------------------------------

/// Broadcast controller for `StatusConflictEvent`s emitted by the
/// outbox worker (when reconciling 409 from the status-transition
/// endpoint). UI components listen to its stream to surface a SnackBar
/// telling the user the server overrode their local transition.
///
/// Distinct from `StatusRepository.statusConflictStream`, which fires
/// for synchronous 409s; the outbox path can also produce 409s when
/// draining a queued transition while connectivity returns.
final outboxStatusConflictControllerProvider =
    Provider<StreamController<StatusConflictEvent>>((ref) {
      final controller = StreamController<StatusConflictEvent>.broadcast();
      ref.onDispose(controller.close);
      return controller;
    });

/// Read-only view of the outbox conflict stream. Screens watch this to
/// receive non-blocking SnackBar events.
final outboxStatusConflictStreamProvider = StreamProvider<StatusConflictEvent>(
  (ref) => ref.watch(outboxStatusConflictControllerProvider).stream,
);

/// Single dispatcher instance for the bookings module. Created once per
/// session and held for the lifetime of the provider container.
final bookingsOutboxDispatcherProvider = Provider<BookingsOutboxDispatcher>(
  (ref) => BookingsOutboxDispatcher(
    db: ref.read(appDatabaseProvider),
    bookingApi: ref.read(bookingApiProvider),
    clientApi: ref.read(clientApiProvider),
    assignmentApi: ref.read(assignmentApiProvider),
    paymentApi: ref.read(paymentApiProvider),
    packageApi: ref.read(packageApiProvider),
    reEditApi: ref.read(reEditApiProvider),
    taskProgressApi: ref.read(taskProgressApiProvider),
    conflictSink: ref.read(outboxStatusConflictControllerProvider).sink,
  ),
);

/// The single OutboxWorker instance. Started by the app shell once
/// connectivity wiring is available; auto-disposes when the provider
/// container tears down.
final outboxWorkerProvider = Provider<OutboxWorker>((ref) {
  final worker = OutboxWorker(
    db: ref.read(appDatabaseProvider),
    dispatcher: ref.read(bookingsOutboxDispatcherProvider),
  );
  ref.onDispose(worker.stop);
  return worker;
});
