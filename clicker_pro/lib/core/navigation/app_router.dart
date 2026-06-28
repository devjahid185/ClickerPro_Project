// lib/core/navigation/app_router.dart
//
// Central route table for `MaterialApp.onGenerateRoute`. Every named route
// listed in `RouteNames` resolves to a widget here. Routes that are still
// stubs in this slice fall through to a small "Coming soon" screen so deep
// links never crash the app.
//
// Page transition contract (matches `slideFromRightRoute` in login_screen.dart):
//   • Slide from right + fade-in over 280ms (Cubic(0.2, 0.8, 0.2, 1))
//   • Reverse over 200ms (Curves.easeIn)
//
// Auth-aware redirect: protected routes returning to `LoginScreen` happens
// at the screen level (Splash + 401 force-logout already handle that path).
// We additionally guard programmatic `pushNamed` calls here for safety.

import 'package:flutter/material.dart';

import '../role/capability.dart';
import '../role/role_gated_screen.dart';
import '../../features/entitlements/application/entitlement_providers.dart';
import '../../features/entitlements/presentation/gated_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/manager_invite_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bookings/presentation/booking_detail_screen.dart';
import '../../features/bookings/presentation/booking_edit_screen.dart';
import '../../features/bookings/presentation/booking_list_screen.dart';
import '../../features/bookings/presentation/calendar_screen.dart';
import '../../features/bookings/presentation/packages_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/announcements/presentation/announcements_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/dashboard_customize_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/freelancer/presentation/fl_availability_screen.dart';
import '../../features/freelancer/presentation/fl_checkin_screen.dart';
import '../../features/freelancer/presentation/fl_earnings_screen.dart';
import '../../features/freelancer/presentation/fl_leave_request_screen.dart';
import '../../features/freelancer/presentation/fl_work_history_screen.dart';
import '../../features/gear/presentation/gear_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/legal/presentation/data_export_screen.dart';
import '../../features/legal/presentation/privacy_screen.dart';
import '../../features/legal/presentation/terms_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/language_picker_screen.dart';
import '../../features/onboarding/presentation/onboarding_intro_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/public_booking/presentation/pending_public_bookings_screen.dart';
import '../../features/public_booking/presentation/public_booking_form_screen.dart';
import '../../features/public_booking/presentation/public_booking_success_screen.dart';
import '../../features/rent/presentation/rent_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/freelancer/presentation/fl_badges_screen.dart';
import '../../features/team/presentation/salary_sheet_screen.dart';
import '../../features/team/presentation/team_screen.dart';
import '../../features/invoice/presentation/invoice_screen.dart';
import '../../features/invoice/domain/invoice.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/audit/presentation/audit_log_screen.dart';
import '../../features/crash_reporting/presentation/crash_settings_screen.dart';
import '../../features/whatsapp/presentation/whatsapp_share_sheet.dart';
import '../../features/calendar_sync/presentation/calendar_sync_settings.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/bookings/presentation/waitlist_screen.dart';
import '../../features/finance/presentation/cash_flow_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/petty_cash/presentation/petty_cash_screen.dart';
import '../../features/followup/presentation/followup_screen.dart';
import '../../features/home_widget/presentation/widget_settings_screen.dart';
import '../../features/auth/domain/otp_purpose.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/bookings/presentation/re_edit_requests_screen.dart';
import '../../features/broadcasts/presentation/broadcasts_screen.dart';
import '../../features/performance/presentation/performance_screen.dart';
import '../../features/security/presentation/security_settings_screen.dart';
import '../../features/payments/presentation/payment_entry_screen.dart';
import '../../theme/app_colors.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  /// Hook for `MaterialApp.onGenerateRoute`. Resolves a named route to a
  /// `lensPageRoute`-wrapped widget. Unknown routes fall back to a "Coming
  /// soon" screen so deep links survive the Foundation slice.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Web deep-link: the public self-booking page is shared as a path URL
    // `/book/<token>` (matching the old web app's link format). On Flutter
    // web, `settings.name` is that full path, so it won't hit any exact
    // `case` below — intercept it here and pull the token out of the path.
    final name = settings.name ?? '';
    if (name.startsWith('/book/')) {
      final token = Uri.decodeComponent(name.substring('/book/'.length)).trim();
      if (token.isNotEmpty) {
        return lensPageRoute<void>(PublicBookingFormScreen(token: token));
      }
      return lensPageRoute<void>(
        _ComingSoonRoute(name: 'Public booking (missing token)'),
      );
    }

    switch (settings.name) {
      case RouteNames.splash:
        return lensPageRoute<void>(const SplashScreen());
      case RouteNames.languagePicker:
        return lensPageRoute<void>(const LanguagePickerScreen());
      case RouteNames.onboarding:
        return lensPageRoute<void>(const OnboardingIntroScreen());
      case RouteNames.login:
        return lensPageRoute<void>(const LoginScreen());
      case RouteNames.register:
        return lensPageRoute<void>(const RegisterScreen());
      case RouteNames.forgot:
        return lensPageRoute<void>(const ForgotPasswordScreen());
      case RouteNames.otp:
        final args = settings.arguments;
        if (args is Map<String, String>) {
          return lensPageRoute<void>(
            OtpScreen(
              identifier: args['identifier'] ?? '',
              purpose: OtpPurpose.fromString(args['purpose']),
            ),
          );
        }
        return lensPageRoute<void>(
          _ComingSoonRoute(name: 'OTP (missing args)'),
        );
      case RouteNames.resetPassword:
        final token = settings.arguments;
        if (token is String && token.isNotEmpty) {
          return lensPageRoute<void>(ResetPasswordScreen(token: token));
        }
        return lensPageRoute<void>(
          _ComingSoonRoute(name: 'Reset Password (missing token)'),
        );
      case RouteNames.acceptInvite:
        return lensPageRoute<void>(const ManagerInviteScreen());
      case RouteNames.dashboard:
        return lensPageRoute<void>(const DashboardScreen());
      case RouteNames.dashboardCustomize:
        return lensPageRoute<void>(const DashboardCustomizeScreen());
      case RouteNames.bookings:
        return lensPageRoute<void>(const BookingListScreen());
      case RouteNames.calendar:
        return lensPageRoute<void>(const CalendarScreen());
      case RouteNames.bookingNew:
        return lensPageRoute<void>(const BookingEditScreen());
      case RouteNames.bookingEdit:
        final id = settings.arguments;
        if (id is String && id.isNotEmpty) {
          return lensPageRoute<void>(BookingEditScreen(bookingId: id));
        }
        return lensPageRoute<void>(
          _ComingSoonRoute(name: 'Booking edit (missing id)'),
        );
      case RouteNames.bookingDetail:
        final id = settings.arguments;
        if (id is String && id.isNotEmpty) {
          return lensPageRoute<void>(BookingDetailScreen(bookingId: id));
        }
        return lensPageRoute<void>(
          _ComingSoonRoute(name: 'Booking detail (missing id)'),
        );
      case RouteNames.profile:
        return lensPageRoute<void>(const ProfileScreen());
      case RouteNames.settings:
        return lensPageRoute<void>(const SettingsScreen());
      case RouteNames.privacy:
        return lensPageRoute<void>(const PrivacyScreen());
      case RouteNames.terms:
        return lensPageRoute<void>(const TermsScreen());
      case RouteNames.dataExport:
        return lensPageRoute<void>(const DataExportScreen());
      case RouteNames.deleteAccount:
        return lensPageRoute<void>(const DeleteAccountScreen());
      case RouteNames.help:
        return lensPageRoute<void>(const HelpScreen());
      case RouteNames.finance:
        return lensPageRoute<void>(const FinanceScreen());
      case RouteNames.financeExpenses:
        return lensPageRoute<void>(const ExpensesScreen());
      case RouteNames.reports:
        return lensPageRoute<void>(const ReportsScreen());
      case RouteNames.notifications:
        return lensPageRoute<void>(const NotificationsScreen());
      case RouteNames.gear:
        return lensPageRoute<void>(const GearScreen());
      case RouteNames.rent:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessRentTracking,
            title: 'Rent Tracking',
            child: RentScreen(),
          ),
        );
      case RouteNames.chat:
        return lensPageRoute<void>(const ChatScreen());
      case RouteNames.team:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessTeam,
            title: 'Team & Staff',
            child: TeamScreen(),
          ),
        );
      case RouteNames.announcements:
        return lensPageRoute<void>(const AnnouncementsScreen());
      case RouteNames.freelancerEarnings:
        return lensPageRoute<void>(const FlEarningsScreen());
      case RouteNames.freelancerBadges:
        return lensPageRoute<void>(const FlBadgesScreen());
      case RouteNames.freelancerAvailability:
        return lensPageRoute<void>(const FlAvailabilityScreen());
      case RouteNames.freelancerCheckin:
        return lensPageRoute<void>(const FlCheckinScreen());
      case RouteNames.freelancerLeave:
        return lensPageRoute<void>(const FlLeaveRequestScreen());
      case RouteNames.freelancerWorkHistory:
        return lensPageRoute<void>(const FlWorkHistoryScreen());
      case RouteNames.teamSalarySheet:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessTeam,
            title: 'Salary Sheet',
            child: SalarySheetScreen(),
          ),
        );

      // Public booking flow — explicitly NOT auth-guarded; the visitor
      // arrives via a token-bearing deep link.
      case RouteNames.publicBooking:
        final token = settings.arguments;
        if (token is String && token.isNotEmpty) {
          return lensPageRoute<void>(PublicBookingFormScreen(token: token));
        }
        return lensPageRoute<void>(
          _ComingSoonRoute(name: 'Public booking (missing token)'),
        );
      case RouteNames.publicBookingSuccess:
        final requestId = settings.arguments as String?;
        return lensPageRoute<void>(
          PublicBookingSuccessScreen(requestId: requestId),
        );
      case RouteNames.pendingPublicBookings:
        return lensPageRoute<void>(const PendingPublicBookingsScreen());
      case RouteNames.packages:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessPackages,
            title: 'Packages',
            child: PackagesScreen(),
          ),
        );

      case RouteNames.invoice:
        final invoice = settings.arguments;
        return lensPageRoute<void>(
          RoleGatedScreen(
            capability: Capability.accessInvoice,
            title: 'Invoices',
            child: invoice is Invoice
                ? InvoiceScreen(invoice: invoice)
                : const InvoiceScreen(),
          ),
        );
      case RouteNames.backup:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.viewFinancials,
            title: 'Backup & Restore',
            child: BackupScreen(),
          ),
        );
      case RouteNames.auditLog:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.viewFinancials,
            title: 'Audit Log',
            child: AuditLogScreen(),
          ),
        );
      case RouteNames.crashSettings:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.viewFinancials,
            title: 'Crash Reports',
            child: CrashSettingsScreen(),
          ),
        );
      case RouteNames.whatsappShare:
        final args = settings.arguments;
        if (args is Map<String, String>) {
          return lensPageRoute<void>(
            WhatsAppShareSheet(
              clientName: args['clientName'] ?? '',
              clientPhone: args['clientPhone'] ?? '',
              eventName: args['eventName'] ?? '',
              eventDate: args['eventDate'] ?? '',
              eventTime: args['eventTime'] ?? '',
              venue: args['venue'] ?? '',
              amount: args['amount'] ?? '',
              total: args['total'] ?? '',
              advance: args['advance'] ?? '',
              due: args['due'] ?? '',
              packageName: args['packageName'] ?? '',
            ),
          );
        }
        return lensPageRoute<void>(const WhatsAppShareSheet());
      case RouteNames.calendarSyncSettings:
        return lensPageRoute<void>(const CalendarSyncSettings());
      case RouteNames.reminders:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessReminders,
            title: 'Reminders',
            child: GatedScreen(
              featureKey: Features.reminders,
              featureName: 'Reminders',
              child: RemindersScreen(),
            ),
          ),
        );
      case RouteNames.waitlist:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessWaitlist,
            title: 'Waitlist',
            child: GatedScreen(
              featureKey: Features.waitlist,
              featureName: 'Waitlist',
              child: WaitlistScreen(),
            ),
          ),
        );
      case RouteNames.cashFlow:
        return lensPageRoute<void>(const CashFlowScreen());
      case RouteNames.pettyCash:
        return lensPageRoute<void>(const PettyCashScreen());
      case RouteNames.followup:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.accessFollowup,
            title: 'Client Follow-up',
            child: FollowupScreen(),
          ),
        );
      case RouteNames.widgetSettings:
        return lensPageRoute<void>(const WidgetSettingsScreen());
      case RouteNames.performance:
        return lensPageRoute<void>(const PerformanceScreen());
      case RouteNames.reEditRequests:
        return lensPageRoute<void>(
          const RoleGatedScreen(
            capability: Capability.requestReEdit,
            title: 'Re-edit Requests',
            child: ReEditRequestsScreen(),
          ),
        );
      case RouteNames.calendarSync:
        return lensPageRoute<void>(const CalendarSyncSettings());
      case RouteNames.paymentEntry:
        return lensPageRoute<void>(const PaymentEntryScreen());
      case RouteNames.broadcasts:
        return lensPageRoute<void>(const BroadcastsScreen());
      case RouteNames.securitySettings:
        return lensPageRoute<void>(const SecuritySettingsScreen());
      // bookings / calendar / finance / team are stubs in this slice. Phase 2
      // wires them. Until then we render a consistent "Coming soon" page.
      default:
        return lensPageRoute<void>(
          _ComingSoonRoute(name: _routeLabel(settings.name)),
        );
    }
  }

  /// Page-route helper exposed for callers that still push widgets directly
  /// (e.g. legacy `Navigator.push(context, AppRouter.lensPageRoute(...))`).
  /// Same animation tokens as the auth-screen slide-from-right transition.
  static Route<T> lensPageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, anim, secondaryAnim, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: anim,
                curve: const Cubic(0.2, 0.8, 0.2, 1),
                reverseCurve: Curves.easeIn,
              ),
            );
        final fade = CurvedAnimation(
          parent: anim,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          reverseCurve: Curves.easeIn,
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  static String _routeLabel(String? name) {
    if (name == null || name.isEmpty) return 'Coming soon';
    // '/data-export' → 'Data Export'
    final cleaned = name.replaceFirst('/', '').replaceAll('-', ' ');
    if (cleaned.isEmpty) return 'Coming soon';
    return cleaned
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}

class _ComingSoonRoute extends StatelessWidget {
  const _ComingSoonRoute({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.rocket_launch_outlined,
                color: AppColors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming soon',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
