// lib/core/booking_status/booking_status_machine.dart
//
// Pure transition predicate for the Booking status flow.
//
// No I/O, no Riverpod, no Drift, no platform imports — this file is referenced
// from both the client repository layer and the unit / property tests, and must
// remain side-effect free so it can be exhaustively quantified over its domain.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Booking Status
// Machine" section. Validates Requirements 3.1 through 3.7.

import '../../features/auth/domain/user_role.dart';
import 'booking_status.dart';

class BookingStatusMachine {
  const BookingStatusMachine._();

  /// Allowed forward transitions (Requirement 3.1).
  static const Map<BookingStatus, BookingStatus> _forward = {
    BookingStatus.pending: BookingStatus.confirmed,
    BookingStatus.confirmed: BookingStatus.inProgress,
    BookingStatus.inProgress: BookingStatus.shotComplete,
    BookingStatus.shotComplete: BookingStatus.delivered,
    BookingStatus.delivered: BookingStatus.completed,
  };

  /// Statuses from which a cancel transition is allowed (Requirement 3.2).
  /// `completed` and `cancelled` are deliberately excluded — once a booking
  /// reaches a terminal state, no further transitions are permitted.
  static const Set<BookingStatus> _cancellableFrom = {
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.inProgress,
    BookingStatus.shotComplete,
    BookingStatus.delivered,
  };

  /// True iff `(from -> to)` is one of the enumerated transitions in
  /// Requirement 3.1 (forward) or 3.2 (cancel). All other transitions are
  /// rejected per Requirement 3.3.
  static bool isAllowedTransition(BookingStatus from, BookingStatus to) {
    if (to == BookingStatus.cancelled) return _cancellableFrom.contains(from);
    return _forward[from] == to;
  }

  /// True iff [role] is permitted to apply the `(from -> to)` transition,
  /// independent of whether the transition itself is structurally allowed.
  ///
  /// - Owner / Both: every transition (Requirement 3.4).
  /// - Manager: forward transitions only — never cancel (Requirement 3.6).
  /// - Freelancer: no event-level transitions at all (Requirement 3.7).
  static bool canRoleApply(
    UserRole role,
    BookingStatus from,
    BookingStatus to,
  ) {
    if (role == UserRole.freelancer) return false;
    if (to == BookingStatus.cancelled && role == UserRole.manager) return false;
    return true;
  }

  /// Single composite predicate that gates every status mutation.
  ///
  /// Validates Requirements 3.1–3.7. The `Status_Repository` MUST call this
  /// before persisting a `StatusHistory` row; the backend re-runs the same
  /// predicate server-side as the source of truth.
  static bool canTransition(
    UserRole role,
    BookingStatus from,
    BookingStatus to,
  ) => isAllowedTransition(from, to) && canRoleApply(role, from, to);

  /// The next forward status from [from], or `null` when [from] is a terminal
  /// state (`completed` or `cancelled`). Used by the UI to decide whether to
  /// render the "Advance status" affordance and what label to put on it.
  static BookingStatus? nextForward(BookingStatus from) => _forward[from];

  /// Statuses that assert the shoot already happened. Reaching them
  /// before the event's end time would mean "tomorrow's event completed
  /// today" — structurally valid but physically impossible.
  static const Set<BookingStatus> _postEventStatuses = {
    BookingStatus.shotComplete,
    BookingStatus.delivered,
    BookingStatus.completed,
  };

  /// True when transitioning to [to] is chronologically possible: the
  /// post-event statuses unlock only once the event's end time has
  /// passed. [endTime] is the booking's "HH:mm" string; unparseable
  /// values fall back to end-of-day so the guard never blocks a real
  /// past event on bad data.
  static bool isTimeAllowed(
    BookingStatus to,
    DateTime eventDate,
    String endTime, {
    DateTime? now,
  }) {
    if (!_postEventStatuses.contains(to)) return true;
    final parts = endTime.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 23) : 23;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 59) : 59;
    final eventEnd = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      h.clamp(0, 23),
      m.clamp(0, 59),
    );
    return !(now ?? DateTime.now()).isBefore(eventEnd);
  }
}
