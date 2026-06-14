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
    },
    Capability.toggleDistribution: {UserRole.owner, UserRole.both},
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
    Capability.editBooking: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.deleteBooking: {UserRole.owner, UserRole.both},
    Capability.advanceBookingStatus: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
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
    Capability.editAssignment: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
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
    Capability.accessTeam: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessInvoice: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessTax: {UserRole.owner, UserRole.both},
    Capability.accessPackages: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessDelivery: {UserRole.owner, UserRole.both, UserRole.manager},
    Capability.accessDailyTasks: {
      UserRole.owner,
      UserRole.both,
      UserRole.manager,
    },
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
