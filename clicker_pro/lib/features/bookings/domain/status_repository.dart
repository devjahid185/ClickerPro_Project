// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/booking_status/booking_status.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../auth/domain/user_role.dart';
import 'status_history_entry.dart';

/// StatusHistory append + transition gating via `BookingStatusMachine`.
///
/// The append-only nature of [StatusHistoryEntry] (Tier C) is enforced at
/// the DAO level; this contract surfaces the user-driven transition
/// entry-point. Implementations:
/// 1. Verify `BookingStatusMachine.canTransition(role, expectedFrom, to)`
///    and throw [StatusTransitionDeniedException] when it returns false.
/// 2. Commit locally first (insert a pending [StatusHistoryEntry] +
///    update `Booking.status`) before any network call.
/// 3. Enqueue an outbox item; on a 409 from the server the worker drops
///    the local pending row and emits a [StatusConflictEvent] on
///    [statusConflictStream] for the UI to consume.
abstract class StatusRepository {
  /// Live local-first append-only history for a booking.
  Stream<List<StatusHistoryEntry>> watchHistory(String bookingId);

  /// Verifies `BookingStatusMachine.canTransition(role, from, to)` before
  /// writing.
  ///
  /// Throws [StatusTransitionDeniedException] on invalid transition or
  /// insufficient role; throws `StatusConflictException` when the server
  /// returns 409 (the implementation catches this internally only when
  /// reconciling via the outbox; a direct synchronous transition surfaces
  /// the conflict to the caller).
  Future<void> transition({
    required String bookingId,
    required BookingStatus expectedFrom,
    required BookingStatus to,
    required String changedByUserId,
    required RolePolicy policy,
    String? note,
  });

  /// Non-blocking stream of 409 reconciliations. The UI subscribes to
  /// surface a SnackBar telling the user the server overrode their local
  /// transition with `serverStatus`.
  Stream<StatusConflictEvent> get statusConflictStream;
}

/// Emitted by [StatusRepository.statusConflictStream] when the outbox
/// worker reconciles a 409 from the server's status-transition endpoint.
///
/// Carries the booking id, the server's authoritative current status
/// (which the local store has just adopted), and the status the user
/// originally attempted — enough for the UI to render a precise
/// "Status changed remotely; we kept the server value" message.
class StatusConflictEvent {
  const StatusConflictEvent({
    required this.bookingId,
    required this.serverStatus,
    required this.attemptedTo,
  });

  /// Local id of the booking whose status was reconciled.
  final String bookingId;

  /// The server's authoritative current status. The local
  /// `Booking.status` has been updated to this value before the event is
  /// emitted.
  final BookingStatus serverStatus;

  /// The status the user originally attempted to transition to. Useful
  /// for the SnackBar copy ("you tried X, server is at Y").
  final BookingStatus attemptedTo;

  @override
  String toString() =>
      'StatusConflictEvent(bookingId: $bookingId, serverStatus: '
      '${serverStatus.name}, attemptedTo: ${attemptedTo.name})';
}

/// Thrown by [StatusRepository.transition] when the requested transition
/// is rejected client-side — either because
/// `BookingStatusMachine.isAllowedTransition(from, to)` is `false` or
/// because the role cannot apply the otherwise-allowed transition.
///
/// Distinct from `RolePolicyDeniedException`: this exception encodes a
/// state-machine concern (illegal state graph edge) rather than a generic
/// [Capability] gate failure, so the UI can render a more specific
/// message ("You can't move from delivered back to inProgress").
class StatusTransitionDeniedException implements Exception {
  StatusTransitionDeniedException({
    required this.role,
    required this.from,
    required this.to,
    String? message,
  }) : message =
           message ??
           'Transition from ${from.name} to ${to.name} is not allowed '
               'for role ${role.name}.';

  /// The role that attempted the transition.
  final UserRole role;

  /// The booking's current status (the `expectedFrom` the caller
  /// supplied).
  final BookingStatus from;

  /// The status the caller attempted to move to.
  final BookingStatus to;

  /// Human-readable explanation, suitable for surfacing in a SnackBar.
  final String message;

  @override
  String toString() =>
      'StatusTransitionDeniedException(role: $role, from: $from, to: $to): '
      '$message';
}
