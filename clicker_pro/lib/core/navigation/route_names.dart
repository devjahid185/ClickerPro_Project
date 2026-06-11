// lib/core/navigation/route_names.dart
//
// Central route name registry. Every screen exposed via the app router
// declares its name here so callers reach screens by `Navigator.pushNamed`
// rather than constructing widgets inline.

class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String languagePicker = '/language';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgot = '/forgot';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';
  static const String acceptInvite = '/accept-invite';

  static const String dashboard = '/dashboard';
  static const String bookings = '/bookings';

  // ─── Bookings module ───
  static const String calendar = '/calendar';
  static const String bookingNew = '/booking/new';
  static const String bookingEdit = '/booking/edit'; // used with arguments
  static const String bookingDetail = '/booking/detail'; // used with arguments
  static const String reEditRequests = '/re-edit-requests';
  static const String publicBooking = '/public/booking';
  static const String publicBookingSuccess = '/public/booking/success';
  static const String pendingPublicBookings = '/bookings/pending-public';
  static const String packages = '/bookings/packages';

  static const String finance = '/finance';
  static const String financeExpenses = '/finance/expenses';
  static const String reports = '/reports';
  static const String performance = '/performance';
  static const String notifications = '/notifications';
  static const String gear = '/gear';
  static const String rent = '/rent';
  static const String chat = '/chat';
  static const String team = '/team';
  static const String announcements = '/announcements';
  static const String freelancerEarnings = '/freelancer/earnings';
  static const String freelancerBadges = '/freelancer/badges';
  static const String freelancerAvailability = '/freelancer/availability';
  static const String freelancerCheckin = '/freelancer/checkin';
  static const String freelancerLeave = '/freelancer/leave';
  static const String freelancerWorkHistory = '/freelancer/work-history';
  static const String teamSalarySheet = '/team/salary-sheet';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // ─── Dashboard Customize module (MOD-62) ───
  static const String dashboardCustomize = '/dashboard/customize';

  // ─── Security module (PROD-04) ───
  static const String securitySettings = '/security';

  // ─── Invoice module ───
  static const String invoice = '/invoice';

  // ─── Payments module ───
  static const String paymentEntry = '/payment/entry';

  // ─── WhatsApp module ───
  static const String whatsappShare = '/whatsapp/share';

  // ─── Calendar Sync module ───
  static const String calendarSync = '/calendar-sync';
  static const String calendarSyncSettings = '/calendar-sync/settings';

  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String help = '/help';

  // ─── Reminders module (MOD-52) ───
  static const String reminders = '/reminders';

  // ─── Waitlist module (MOD-57) ───
  static const String waitlist = '/waitlist';

  // ─── Cash Flow module (MOD-53) ───
  static const String cashFlow = '/cash-flow';

  // ─── Petty Cash module (MOD-54) ───
  static const String pettyCash = '/petty-cash';

  // ─── Follow-up module (MOD-65) ───
  static const String followup = '/followup';

  // ─── Platform Broadcasts ───
  static const String broadcasts = '/broadcasts';

  static const String dataExport = '/data-export';
  static const String deleteAccount = '/delete-account';

  // ─── Home Widget module (MOD-63) ───
  static const String widgetSettings = '/widget-settings';

  // ─── Production & Reliability module ───
  static const String backup = '/backup';
  static const String auditLog = '/audit-log';
  static const String crashSettings = '/crash-settings';
}
