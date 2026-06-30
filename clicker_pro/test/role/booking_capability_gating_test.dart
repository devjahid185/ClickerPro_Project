// test/role/booking_capability_gating_test.dart
//
// Property 11: Capability gating round-trip (booking-specific)
// For every (role, capability) pair where capability is one of the 18 booking
// capabilities, RolePolicy(role).can(capability) is true iff the static
// _matrix[capability] set contains role.

import 'package:clicker_pro/core/role/capability.dart';
import 'package:clicker_pro/core/role/role_policy.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bookingCapabilities = {
    Capability.viewAllBookings,
    Capability.viewAssignedBookings,
    Capability.viewOwnBookings,
    Capability.createBooking,
    Capability.editBooking,
    Capability.deleteBooking,
    Capability.advanceBookingStatus,
    Capability.cancelBooking,
    Capability.viewBookingPayments,
    Capability.viewBookingPayouts,
    Capability.editBookingPayments,
    Capability.editAssignment,
    Capability.toggleHidePayment,
    Capability.generatePublicBookingToken,
    Capability.approvePublicBooking,
    Capability.requestReEdit,
    Capability.assignReEdit,
    Capability.updateTaskProgress,
  };

  group('Property 11: Capability gating round-trip (Feature: bookings-module)', () {
    test('For every (role, booking-capability) pair, can() matches matrix', () {
      final matrix = RolePolicy.matrixForTesting;
      for (final role in UserRole.values) {
        // webAdmin is a superadmin that bypasses the matrix entirely —
        // RolePolicy.can() short-circuits to true for every capability.
        if (role == UserRole.webAdmin) continue;
        final policy = RolePolicy(role);
        for (final cap in bookingCapabilities) {
          final expected = matrix[cap]?.contains(role) ?? false;
          expect(
            policy.can(cap),
            expected,
            reason:
                'RolePolicy($role).can($cap) should be $expected per the static matrix',
          );
        }
      }
    });

    test('All 18 booking capabilities are in the matrix', () {
      final matrix = RolePolicy.matrixForTesting;
      for (final cap in bookingCapabilities) {
        expect(
          matrix.containsKey(cap),
          isTrue,
          reason: '$cap missing from RolePolicy._matrix',
        );
      }
    });

    test('Owner has all 18 booking capabilities', () {
      final policy = const RolePolicy(UserRole.owner);
      for (final cap in bookingCapabilities) {
        expect(policy.can(cap), isTrue, reason: 'Owner should have $cap');
      }
    });

    test('Both has all 18 booking capabilities', () {
      final policy = const RolePolicy(UserRole.both);
      for (final cap in bookingCapabilities) {
        expect(policy.can(cap), isTrue, reason: 'Both should have $cap');
      }
    });

    test('Freelancer cannot manage other people\'s bookings', () {
      final policy = const RolePolicy(UserRole.freelancer);
      expect(policy.can(Capability.viewAllBookings), isFalse);
      expect(policy.can(Capability.cancelBooking), isFalse);
      expect(policy.can(Capability.deleteBooking), isFalse);
      expect(policy.can(Capability.toggleHidePayment), isFalse);
      expect(policy.can(Capability.generatePublicBookingToken), isFalse);
      expect(policy.can(Capability.approvePublicBooking), isFalse);
    });

    test('Manager cannot cancel bookings or toggle hide-payment', () {
      final policy = const RolePolicy(UserRole.manager);
      expect(policy.can(Capability.cancelBooking), isFalse);
      expect(policy.can(Capability.deleteBooking), isFalse);
      expect(policy.can(Capability.toggleHidePayment), isFalse);
    });

    test('FL-12: every working role can log their own booking', () {
      // createOwnBooking is the gate the repository uses on create, so a
      // Freelancer must hold it to save their short-form freelance booking.
      for (final role in const [
        UserRole.owner,
        UserRole.both,
        UserRole.manager,
        UserRole.freelancer,
      ]) {
        expect(
          RolePolicy(role).can(Capability.createOwnBooking),
          isTrue,
          reason: '$role should be able to log their own booking',
        );
      }
    });
  });
}
