// lib/core/role/capability.dart
//
// Discrete UI/data actions gated by RolePolicy. Replaces scattered
// `if (role == 'Owner')` checks across screens.

enum Capability {
  // Profile
  editStudioBranding,
  editGearInventory,
  joinAnotherStudio,
  // Dashboard
  viewFinancials,
  viewTeamSection,
  // Settings
  toggleDistribution,
  toggleVat,
  // Auth
  changeRole,
  generateTeamInvite,
  deleteOwnAccount,
  // Bookings module
  viewAllBookings,
  viewAssignedBookings,
  viewOwnBookings,
  createBooking,
  // FL-12: a Freelancer can log their OWN short-form bookings even though they
  // don't hold the full studio `createBooking`. Owner/Manager/Both also hold
  // this (a superset action), so the booking-create path can gate on it.
  createOwnBooking,
  editBooking,
  deleteBooking,
  advanceBookingStatus,
  cancelBooking,
  viewBookingPayments,
  viewBookingPayouts,
  editBookingPayments,
  editAssignment,
  toggleHidePayment,
  generatePublicBookingToken,
  approvePublicBooking,
  requestReEdit,
  assignReEdit,
  updateTaskProgress,
  // Announcements
  createAnnouncement,
  viewAnnouncements,
  // Owner/Manager-only operational areas (hidden from Freelancer).
  // A Freelancer works *for* studios; these are studio-management surfaces.
  accessTeam,
  accessInvoice,
  accessTax,
  accessPackages,
  accessDelivery,
  accessDailyTasks,
  accessFollowup,
  accessReminders,
  accessWaitlist,
  accessRentTracking,
}
