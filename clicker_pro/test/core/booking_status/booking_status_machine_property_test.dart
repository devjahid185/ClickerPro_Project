// test/core/booking_status/booking_status_machine_property_test.dart
//
// Property 1 — BookingStatusMachine soundness.
//
// The state space (BookingStatus × BookingStatus × UserRole) has only
// 7 × 7 × 4 = 196 elements, so we run the property *exhaustively* rather
// than via random sampling.  This rules out implementation drift — if
// anyone ever adds a new transition or relaxes a role guard the property
// will surface the divergence on the next CI run.
//
// Predicate (per design.md "Booking Status Machine"):
//
//   structurallyAllowed(from, to)
//     := _forward[from] == to
//        OR (to == cancelled AND from ∈ _cancellableFrom)
//
//   roleAllowed(role, from, to)
//     := role != freelancer
//        AND NOT (to == cancelled AND role == manager)
//
//   canTransition(role, from, to)
//     := structurallyAllowed(from, to) AND roleAllowed(role, from, to)
//
// `glados` re-exports `package:test/test.dart`, so `group`, `test`,
// `expect`, and matchers are available without pulling in flutter_test.

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/core/booking_status/booking_status_machine.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:glados/glados.dart';

// ─── Static reference predicate ──────────────────────────────────────
//
// This is the contract of `BookingStatusMachine` rewritten in plain
// Dart, with no shared imports or mutable state.  The point of the test
// is to verify that the production implementation matches THIS — so we
// deliberately keep the body verbose and free of helper indirection.

const Map<BookingStatus, BookingStatus> _expectedForward = {
  BookingStatus.pending: BookingStatus.confirmed,
  BookingStatus.confirmed: BookingStatus.inProgress,
  BookingStatus.inProgress: BookingStatus.shotComplete,
  BookingStatus.shotComplete: BookingStatus.delivered,
  BookingStatus.delivered: BookingStatus.completed,
};

const Set<BookingStatus> _expectedCancellableFrom = {
  BookingStatus.pending,
  BookingStatus.confirmed,
  BookingStatus.inProgress,
  BookingStatus.shotComplete,
  BookingStatus.delivered,
};

bool _expectedStructurallyAllowed(BookingStatus from, BookingStatus to) {
  if (to == BookingStatus.cancelled) {
    return _expectedCancellableFrom.contains(from);
  }
  return _expectedForward[from] == to;
}

bool _expectedRoleAllowed(UserRole role, BookingStatus from, BookingStatus to) {
  if (role == UserRole.freelancer) return false;
  if (to == BookingStatus.cancelled && role == UserRole.manager) return false;
  return true;
}

bool _expectedCanTransition(
  UserRole role,
  BookingStatus from,
  BookingStatus to,
) {
  return _expectedStructurallyAllowed(from, to) &&
      _expectedRoleAllowed(role, from, to);
}

void main() {
  group('BookingStatusMachine soundness — exhaustive', () {
    // ─────────────────────────────────────────────────────────────
    // Property 1a — `isAllowedTransition` matches the structural
    // predicate over all (from, to) pairs.  7 × 7 = 49 cases.
    // ─────────────────────────────────────────────────────────────
    test('isAllowedTransition matches structural predicate (49 pairs)', () {
      for (final from in BookingStatus.values) {
        for (final to in BookingStatus.values) {
          final actual = BookingStatusMachine.isAllowedTransition(from, to);
          final expected = _expectedStructurallyAllowed(from, to);

          expect(
            actual,
            equals(expected),
            reason:
                'isAllowedTransition($from, $to) returned $actual, '
                'expected $expected',
          );
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // Property 1b — `canRoleApply` matches the role predicate over
    // all (role, from, to) triples.  4 × 7 × 7 = 196 cases.
    // ─────────────────────────────────────────────────────────────
    test('canRoleApply matches role predicate (196 triples)', () {
      for (final role in UserRole.values) {
        for (final from in BookingStatus.values) {
          for (final to in BookingStatus.values) {
            final actual = BookingStatusMachine.canRoleApply(role, from, to);
            final expected = _expectedRoleAllowed(role, from, to);

            expect(
              actual,
              equals(expected),
              reason:
                  'canRoleApply($role, $from, $to) returned $actual, '
                  'expected $expected',
            );
          }
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // Property 1c — `canTransition` is the conjunction of the two
    // predicates over the full cartesian product.  This is the
    // statement explicitly listed in tasks.md / design.md.
    // ─────────────────────────────────────────────────────────────
    test('canTransition matches structural ∧ role predicate (196 triples)', () {
      for (final role in UserRole.values) {
        for (final from in BookingStatus.values) {
          for (final to in BookingStatus.values) {
            final actual = BookingStatusMachine.canTransition(role, from, to);
            final expected = _expectedCanTransition(role, from, to);

            expect(
              actual,
              equals(expected),
              reason:
                  'canTransition($role, $from, $to) returned $actual, '
                  'expected $expected',
            );
          }
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // Property 1d — `nextForward` round-trip:
    //   - returns null for terminal states (completed, cancelled)
    //   - otherwise returns the unique allowed forward target
    //
    // This sub-property guarantees that the affordance the UI reads
    // ("Advance status" button label / visibility) never disagrees
    // with the gate that the machine actually enforces.
    // ─────────────────────────────────────────────────────────────
    test('nextForward agrees with _forward map for every status', () {
      for (final from in BookingStatus.values) {
        final actual = BookingStatusMachine.nextForward(from);
        final expected = _expectedForward[from]; // null for terminal states

        expect(
          actual,
          equals(expected),
          reason: 'nextForward($from) returned $actual, expected $expected',
        );

        // If a forward target exists, the corresponding transition MUST be
        // structurally allowed (and conversely, no other forward step may
        // be allowed from this status).
        if (expected != null) {
          expect(
            BookingStatusMachine.isAllowedTransition(from, expected),
            isTrue,
            reason: 'nextForward($from) = $expected but is not allowed',
          );
        }

        // Terminal states must produce no forward transition at all.
        if (from == BookingStatus.completed ||
            from == BookingStatus.cancelled) {
          expect(
            actual,
            isNull,
            reason: 'Terminal status $from must have no forward target',
          );
          for (final to in BookingStatus.values) {
            if (to == from) continue;
            expect(
              BookingStatusMachine.isAllowedTransition(from, to),
              isFalse,
              reason:
                  'No transition out of terminal status $from allowed, '
                  'but ($from -> $to) was accepted',
            );
          }
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // Property 1e — Freelancer is fully locked out (Requirement 3.7).
    // Iterates the 49 (from, to) pairs and asserts that
    // `canTransition(freelancer, ...)` always returns false, regardless
    // of structural validity.  Catches the easy-to-introduce bug
    // where someone bolts on a "freelancer can advance their own
    // booking" exception without updating the matrix doc.
    // ─────────────────────────────────────────────────────────────
    test('freelancer cannot apply any transition (49 pairs)', () {
      for (final from in BookingStatus.values) {
        for (final to in BookingStatus.values) {
          expect(
            BookingStatusMachine.canTransition(UserRole.freelancer, from, to),
            isFalse,
            reason:
                'Freelancer must not be able to apply ($from -> $to), '
                'but canTransition returned true',
          );
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // Property 1f — Manager cannot cancel anything (Requirement 3.6).
    // Asserts that for every `from`, `canTransition(manager, from,
    // cancelled)` is false, independent of whether the structural
    // predicate would otherwise allow the cancel.
    // ─────────────────────────────────────────────────────────────
    test('manager cannot cancel from any status (7 cases)', () {
      for (final from in BookingStatus.values) {
        expect(
          BookingStatusMachine.canTransition(
            UserRole.manager,
            from,
            BookingStatus.cancelled,
          ),
          isFalse,
          reason:
              'Manager must not be able to cancel from $from, but '
              'canTransition returned true',
        );
      }
    });
  });
}
