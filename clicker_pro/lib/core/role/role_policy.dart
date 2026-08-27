// lib/core/role/role_policy.dart
//
// Single source of truth for role → capability mapping.
// Validated by Property tests (foundation-mvp Properties 5, 7, 9).

import '../../features/auth/domain/user_role.dart';
import 'capability.dart';

class RolePolicy {
  const RolePolicy(this.role);
  final UserRole role;

  static const Map<Capability, Set<UserRole>> _matrix = {
    Capability.editStudioBranding: {UserRole.owner, UserRole.both},
    Capability.editGearInventory: {UserRole.freelancer, UserRole.both},
    Capability.joinAnotherStudio: {UserRole.freelancer, UserRole.both},
    Capability.viewFinancials: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
    Capability.viewTeamSection: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    // Distribution lifts the freelancer 1-event-per-shift cap, so it is only
    // relevant to users who take freelance work. Owners are never limited and
    // therefore never see the option.
    Capability.toggleDistribution: {UserRole.freelancer, UserRole.both},
    Capability.toggleVat: {UserRole.owner, UserRole.both},
    Capability.changeRole: {UserRole.owner, UserRole.freelancer, UserRole.both},
    Capability.generateTeamInvite: {UserRole.owner, UserRole.both},
    Capability.deleteOwnAccount: {
      UserRole.owner,
      UserRole.freelancer,
      UserRole.both,
      UserRole.manager,
    },
    // Bookings module
    Capability.viewAllBookings: {UserRole.owner, UserRole.both},
    Capability.viewAssignedBookings: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
    Capability.viewOwnBookings: {
      UserRole.owner,
      UserRole.freelancer,
      UserRole.both,
      UserRole.manager,
    },
    Capability.createBooking: {UserRole.owner, UserRole.both, UserRole.manager},
    // FL-12: every working role can log their own booking (Freelancer uses the
    // short freelance form; Owner/Manager/Both use the full studio form).
    Capability.createOwnBooking: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    Capability.editBooking: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.deleteBooking: {UserRole.owner, UserRole.both},
    // Freelancer inclusion is narrow: BookingStatusMachine.canRoleApply
    // only lets them apply the → shotComplete step ("Shoot Complete"),
    // and the server checks they are assigned to the event.
    Capability.advanceBookingStatus: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    Capability.cancelBooking: {UserRole.owner, UserRole.both},
    Capability.viewBookingPayments: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
    Capability.viewBookingPayouts: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
    Capability.editBookingPayments: {UserRole.owner, UserRole.both},
    // Freelancer inclusion is the distributor flow: an assigned freelancer
    // with Distribution mode ON may add same-role crew / remove themselves.
    // The DistributorPanel gates the UI and the server enforces both rules
    // (must be assigned; may only add their own role; may only delete self).
    Capability.editAssignment: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    Capability.toggleHidePayment: {UserRole.owner, UserRole.both},
    Capability.generatePublicBookingToken: {UserRole.owner, UserRole.both},
    Capability.approvePublicBooking: {UserRole.owner, UserRole.both},
    // Re-edit requests are an Owner/Manager workflow. A Freelancer neither
    // raises nor assigns them.
    Capability.requestReEdit: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.assignReEdit: {UserRole.owner, UserRole.both, UserRole.manager},
    // A Freelancer still updates progress on the events they are assigned to.
    Capability.updateTaskProgress: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    Capability.createAnnouncement: {UserRole.owner, UserRole.both},
    // Owner posts announcements; Manager + Freelancer read them.
    Capability.viewAnnouncements: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    // Studio-management surfaces — never shown to a pure Freelancer.
    Capability.accessTeam: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
      UserRole.freelancer,
    },
    Capability.accessInvoice: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessTax: {UserRole.owner, UserRole.both},
    Capability.accessPackages: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessDelivery: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessFollowup: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessReminders: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
    Capability.accessWaitlist: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessRentTracking: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
  };

  bool can(Capability c) =>
      role == UserRole.webAdmin || (_matrix[c]?.contains(role) ?? false);

  /// Test-only: exposes the static matrix for property-based exhaustiveness.
  static Map<Capability, Set<UserRole>> get matrixForTesting => _matrix;
}
