// lib/shared/widgets/web_nav_shell.dart
//
// Clicker Pro — Web navigation shell (Sunset Studio, from
// design_handoff_clickerpro_web / ClickerPro Dashboard v2.dc.html).
//
// On wide web screens this wraps the routed app in the handoff's chrome:
//   • warm-cream page (#FBF6F0), 24px padding, content centered at 1440px;
//   • a dark-brown (#2B1D12) rounded (30px) sidebar — logo row, profile block
//     with gold-ring avatar + role badge, pill nav (active = cream pill that
//     bleeds to the right edge), and an "Active Team" avatar stack footer;
//   • a shared header per screen — Sora 800 title + Space-Mono date line, a
//     white search pill, and a bell button with a pulsing dot that opens the
//     Notifications dropdown.
//
//   • Mobile + narrow web are untouched (returns the child as-is).
//   • Auth / fullscreen routes (splash, login, register, onboarding, otp) get
//     NO sidebar — they render full-bleed.
//   • Nav items drive the real router via the root navigator key.
//   • All motion honours reduce-motion via the web_motion primitives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/route_names.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/role/capability.dart';
import '../../core/role/role_policy.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/notifications/application/notification_providers.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/profile/application/profile_controllers.dart';
import '../../features/profile/domain/user_model.dart';
import '../../features/search/presentation/global_search_sheet.dart';
import '../../features/team/application/team_providers.dart';
import '../../theme/web_theme.dart';
import 'web_motion.dart';

/// Opens the shared global search sheet from the web chrome — same sheet the
/// mobile dashboard uses, so search behaves identically on web.
void _openGlobalSearch() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  showModalBottomSheet<void>(
    context: ctx,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    isScrollControlled: true,
    builder: (_) => const GlobalSearchSheet(),
  );
}

class _NavDest {
  const _NavDest(this.icon, this.label, this.route, {this.capability});
  final IconData icon;
  final String label;
  final String route;

  /// When set, the item only shows for roles that hold this capability.
  /// `null` means everyone (Dashboard, Calendar, Settings…).
  final Capability? capability;
}

class WebNavShell extends ConsumerStatefulWidget {
  const WebNavShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  final Widget child;
  final String currentRoute;

  static const double _sidebarBreakpoint = 900;
  static const double _sidebarWidth = 248;
  static const double _maxContentWidth = 1440;

  static const Set<String> _fullscreenRoutes = {
    // '/' is the boot/splash state before any named route is tracked — the
    // initial splash is pushed without a route name, so currentRouteName stays
    // '/' until login/dashboard. Treat it as fullscreen so the sidebar never
    // flashes over the splash / login screens.
    '/',
    RouteNames.splash,
    RouteNames.languagePicker,
    RouteNames.onboarding,
    RouteNames.login,
    RouteNames.register,
    RouteNames.forgot,
    RouteNames.otp,
    RouteNames.resetPassword,
    RouteNames.acceptInvite,
    RouteNames.publicBooking,
    RouteNames.publicBookingSuccess,
  };

  // The handoff's 9 primary destinations, in its exact order. Finance is one
  // item (the Finance hub carries Overview / Expenses / Cash Flow / Petty
  // Cash / Salary / Payouts as tabs). Capability gates mirror the mobile
  // drawer so role visibility stays in lockstep.
  static const List<_NavDest> _primary = [
    _NavDest(Icons.dashboard_rounded, 'Dashboard', RouteNames.dashboard),
    _NavDest(Icons.event_note_rounded, 'Bookings', RouteNames.bookings),
    _NavDest(Icons.calendar_month_rounded, 'Calendar', RouteNames.calendar),
    _NavDest(Icons.account_balance_wallet_rounded, 'Finance',
        RouteNames.finance,
        capability: Capability.viewFinancials),
    _NavDest(Icons.groups_rounded, 'Team', RouteNames.team,
        capability: Capability.accessTeam),
    _NavDest(Icons.chat_bubble_outline_rounded, 'Chat', RouteNames.chat),
    _NavDest(Icons.campaign_outlined, 'Announce', RouteNames.announcements,
        capability: Capability.viewAnnouncements),
    _NavDest(Icons.inventory_2_outlined, 'Packages', RouteNames.packages,
        capability: Capability.accessPackages),
    _NavDest(Icons.settings_outlined, 'Settings', RouteNames.settings),
  ];

  // Everything else the mobile app can reach stays reachable on web — feature
  // parity is a hard requirement ("মোবাইল এপের সব ফিচার ওয়েব এপ এ থাকবে").
  // These render below the primary nav under a "MORE" micro-label, in the
  // same pill language.
  static const List<_NavDest> _more = [
    _NavDest(Icons.receipt_long_rounded, 'Invoices', RouteNames.invoice,
        capability: Capability.accessInvoice),
    _NavDest(Icons.payments_rounded, 'Payments', RouteNames.paymentEntry,
        capability: Capability.viewBookingPayments),
    _NavDest(Icons.bar_chart_rounded, 'Reports', RouteNames.reports,
        capability: Capability.viewFinancials),
    _NavDest(Icons.insights_rounded, 'Performance', RouteNames.performance,
        capability: Capability.viewFinancials),
    _NavDest(Icons.edit_note_rounded, 'Re-edit Requests',
        RouteNames.reEditRequests,
        capability: Capability.requestReEdit),
    _NavDest(Icons.hourglass_bottom_rounded, 'Waitlist', RouteNames.waitlist,
        capability: Capability.accessWaitlist),
    _NavDest(Icons.camera_alt_outlined, 'Gear', RouteNames.gear),
    _NavDest(Icons.local_shipping_outlined, 'Delivery', RouteNames.delivery,
        capability: Capability.accessDelivery),
    _NavDest(Icons.follow_the_signs_rounded, 'Follow-up', RouteNames.followup,
        capability: Capability.accessFollowup),
    _NavDest(Icons.alarm_rounded, 'Reminders', RouteNames.reminders,
        capability: Capability.accessReminders),
    _NavDest(Icons.swap_horiz_rounded, 'Rent Tracking', RouteNames.rent,
        capability: Capability.accessRentTracking),
    _NavDest(Icons.cell_tower_rounded, 'Updates', RouteNames.broadcasts),
    _NavDest(Icons.calculate_outlined, 'Calculator', RouteNames.calculator),
    _NavDest(Icons.sticky_note_2_outlined, 'Notes', RouteNames.notes),
    _NavDest(Icons.sync_rounded, 'Calendar Sync',
        RouteNames.calendarSyncSettings),
    _NavDest(Icons.person_outline_rounded, 'Profile', RouteNames.profile),
  ];

  /// Sub-screens keep their parent nav item highlighted (handoff spec):
  /// New Booking / Event Details / Self-Booking → Bookings; the standalone
  /// finance routes → Finance.
  static String _navRouteFor(String route) {
    if (route.startsWith(RouteNames.bookingNew) ||
        route.startsWith(RouteNames.bookingEdit) ||
        route.startsWith(RouteNames.bookingDetail) ||
        route.startsWith(RouteNames.pendingPublicBookings)) {
      return RouteNames.bookings;
    }
    if (route.startsWith(RouteNames.financeExpenses) ||
        route.startsWith(RouteNames.cashFlow) ||
        route.startsWith(RouteNames.teamSalarySheet)) {
      return RouteNames.finance;
    }
    return route;
  }

  /// Header title per route — the handoff's shared header swaps only this.
  static String titleFor(String route) {
    final r = _navRouteFor(route);
    switch (r) {
      case RouteNames.dashboard:
        return 'Dashboard';
      case RouteNames.bookings:
        return 'Bookings';
      case RouteNames.calendar:
        return 'Calendar';
      case RouteNames.finance:
        return 'Finance';
      case RouteNames.team:
        return 'Team';
      case RouteNames.chat:
        return 'Team Chat';
      case RouteNames.announcements:
        return 'Announcements';
      case RouteNames.packages:
        return 'Packages';
      case RouteNames.settings:
        return 'Settings';
      case RouteNames.invoice:
        return 'Invoices';
      case RouteNames.paymentEntry:
        return 'Payments';
      case RouteNames.reports:
        return 'Reports';
      case RouteNames.performance:
        return 'Performance';
      case RouteNames.reEditRequests:
        return 'Re-edit Requests';
      case RouteNames.waitlist:
        return 'Waitlist';
      case RouteNames.gear:
        return 'Gear';
      case RouteNames.delivery:
        return 'Delivery';
      case RouteNames.followup:
        return 'Follow-up';
      case RouteNames.reminders:
        return 'Reminders';
      case RouteNames.rent:
        return 'Rent Tracking';
      case RouteNames.broadcasts:
        return 'Platform Updates';
      case RouteNames.calculator:
        return 'Calculator';
      case RouteNames.notes:
        return 'Notes';
      case RouteNames.calendarSyncSettings:
        return 'Calendar Sync';
      case RouteNames.profile:
        return 'Profile';
      case RouteNames.notifications:
        return 'Notifications';
      default:
        return 'Graphy7';
    }
  }

  @override
  ConsumerState<WebNavShell> createState() => _WebNavShellState();
}

class _WebNavShellState extends ConsumerState<WebNavShell> {
  bool _notifOpen = false;

  bool _isActive(String route) {
    final current = WebNavShell._navRouteFor(widget.currentRoute);
    if (current == route) return true;
    if (route != '/' && current.startsWith('$route/')) return true;
    return false;
  }

  void _go(String route) {
    setState(() => _notifOpen = false);
    if (!_isActive(route)) {
      rootNavigatorKey.currentState?.pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= WebNavShell._sidebarBreakpoint &&
        !WebNavShell._fullscreenRoutes.contains(widget.currentRoute);

    if (!showSidebar) return widget.child;

    // Role-gate the nav: each role only sees the destinations its RolePolicy
    // allows, matching the mobile drawer's visibility.
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = user?.role ?? UserRole.owner;
    final policy = RolePolicy(role);
    bool visible(_NavDest d) =>
        d.capability == null || policy.can(d.capability!);
    final primary = WebNavShell._primary.where(visible).toList();
    final more = WebNavShell._more.where(visible).toList();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: WebTheme.pageBg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: WebNavShell._maxContentWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(
                  user: user,
                  role: role,
                  primary: primary,
                  more: more,
                  isActive: _isActive,
                  onTap: _go,
                ),
                const SizedBox(width: 20),
                // Main column: shared header + the routed screen, with the
                // notifications dropdown floating over it.
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            title: WebNavShell.titleFor(widget.currentRoute),
                            bellOpen: _notifOpen,
                            onBellTap: () =>
                                setState(() => _notifOpen = !_notifOpen),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            // Re-key on route so each screen replays its
                            // entrance (handoff: animations replay on switch).
                            child: WebEntrance(
                              key: ValueKey(widget.currentRoute),
                              offset: 10,
                              child: widget.child,
                            ),
                          ),
                        ],
                      ),
                      if (_notifOpen) ...[
                        // Click-away barrier — closes the dropdown.
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => setState(() => _notifOpen = false),
                          ),
                        ),
                        Positioned(
                          top: 52,
                          right: 0,
                          child: _NotificationsPanel(
                            onClose: () =>
                                setState(() => _notifOpen = false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
/// Shared per-screen header: Sora 800 title + Space-Mono date line, a white
/// search pill, and the bell with a pulsing unread dot.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.bellOpen,
    required this.onBellTap,
  });

  final String title;
  final bool bellOpen;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final dateLine =
        '${DateFormat('EEE · dd MMM yyyy').format(DateTime.now()).toUpperCase()} · DHAKA';
    return WebEntrance(
      offset: 8,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WebTheme.displayStyle(size: 26, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(dateLine,
                  style: WebTheme.label(
                      size: 10, color: WebTheme.inkMuted, tracking: 0.08)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _SearchPill(onTap: _openGlobalSearch),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _Bell(open: bellOpen, onTap: onBellTap),
        ],
      ),
    );
  }
}

/// The handoff's white search pill: orange ⌕, faint placeholder, radius 999.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2B1D12),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⌕',
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 12,
                  color: WebTheme.orange,
                )),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Search client, booking, venue…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    WebTheme.bodyStyle(size: 12.5, color: WebTheme.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 42px white circular bell with the pulsing 7px orange dot. Background turns
/// orange-tint while the dropdown is open (handoff spec).
class _Bell extends StatelessWidget {
  const _Bell({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      enableShadow: false,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: open ? WebTheme.orangeTint : WebTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
              color: open ? WebTheme.orangeTintBorder : WebTheme.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2B1D12),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 20, color: WebTheme.ink),
            Positioned(
              top: 9,
              right: 10,
              child: _PulsingDot(
                size: 7,
                color: WebTheme.orange,
                ringColor: open ? WebTheme.orangeTint : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opacity pulse 1 → 0.45 → 1, 2s infinite (handoff `pulse`). Honours
/// reduce-motion by holding still.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.size,
    required this.color,
    required this.ringColor,
  });

  final double size;
  final Color color;
  final Color ringColor;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final noMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!noMotion && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // 0→0.5→1 maps to opacity 1→0.45→1.
        final t = _c.value;
        final opacity = 1 - (0.55 * (1 - (2 * t - 1).abs()));
        return Opacity(
          opacity: _c.isAnimating ? opacity : 1,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: widget.ringColor, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────── NOTIFICATIONS DROPDOWN
/// The 352px white dropdown under the bell (MOD-44): header + MARK ALL READ,
/// then notification rows with tinted icon tiles and relative times. Reads
/// the real inbox; tapping a row marks it read.
class _NotificationsPanel extends ConsumerWidget {
  const _NotificationsPanel({required this.onClose});
  final VoidCallback onClose;

  static ({String glyph, Color bg}) _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('pay') || c.contains('due') || c.contains('finance')) {
      return (glyph: '৳', bg: WebTheme.dangerTint);
    }
    if (c.contains('deliver') || c.contains('deadline') ||
        c.contains('reminder')) {
      return (glyph: '⏰', bg: WebTheme.orangeTint);
    }
    if (c.contains('weather')) {
      return (glyph: '🌦', bg: WebTheme.nightTint);
    }
    if (c.contains('milestone') || c.contains('delivered') ||
        c.contains('success')) {
      return (glyph: '🎉', bg: WebTheme.successTint);
    }
    return (glyph: '🔔', bg: WebTheme.orangeTint);
  }

  static String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'NOW';
    if (d.inMinutes < 60) return '${d.inMinutes}M';
    if (d.inHours < 24) return '${d.inHours}H';
    return '${d.inDays}D';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxControllerProvider);
    final items = inbox.valueOrNull ?? const <AppNotification>[];
    final recent = items.take(6).toList();

    return WebEntrance(
      offset: 6,
      duration: WebTheme.base,
      child: Container(
        width: 352,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E2B1D12),
              blurRadius: 54,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  Text('Notifications',
                      style: WebTheme.displayStyle(size: 14)),
                  const Spacer(),
                  WebHoverHighlight(
                    onTap: () {
                      final ctrl = ref.read(
                          notificationInboxControllerProvider.notifier);
                      for (final n in items.where((n) => !n.read)) {
                        ctrl.markRead(n.id);
                      }
                    },
                    builder: (context, hovering) => Text(
                      'MARK ALL READ',
                      style: WebTheme.label(
                        size: 9,
                        color: hovering
                            ? WebTheme.orangeDark
                            : WebTheme.orange,
                        tracking: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No notifications yet.',
                  textAlign: TextAlign.center,
                  style:
                      WebTheme.bodyStyle(size: 12, color: WebTheme.inkMuted),
                ),
              )
            else
              for (final n in recent) _row(context, ref, n),
            // Full inbox lives on its own screen.
            WebHoverHighlight(
              onTap: () {
                onClose();
                rootNavigatorKey.currentState
                    ?.pushNamed(RouteNames.notifications);
              },
              builder: (context, hovering) => Container(
                margin: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: hovering ? WebTheme.orangeTint : WebTheme.pageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('VIEW ALL',
                      style: WebTheme.label(
                          size: 9,
                          color: WebTheme.orangeDeep,
                          tracking: 0.12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AppNotification n) {
    final icon = _iconFor(n.category);
    return WebHoverHighlight(
      onTap: () {
        ref
            .read(notificationInboxControllerProvider.notifier)
            .markRead(n.id);
      },
      borderRadius: 12,
      builder: (context, hovering) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.pageBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: icon.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child:
                      Text(icon.glyph, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.category.isEmpty ? 'Notification' : n.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 12.5,
                        weight:
                            n.read ? FontWeight.w500 : FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 11, color: WebTheme.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_relTime(n.sentAt),
                style:
                    WebTheme.label(size: 9, color: WebTheme.inkFaint)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── SIDEBAR
class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.user,
    required this.role,
    required this.primary,
    required this.more,
    required this.isActive,
    required this.onTap,
  });

  final UserModel? user;
  final UserRole role;
  final List<_NavDest> primary;
  final List<_NavDest> more;
  final bool Function(String) isActive;
  final ValueChanged<String> onTap;

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CP';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.owner:
        return 'OWNER';
      case UserRole.both:
        return 'OWNER · SHOOTS';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.freelancer:
        return 'FREELANCER';
      case UserRole.officeStaff:
        return 'OFFICE STAFF';
      case UserRole.webAdmin:
        return 'ADMIN';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user?.name ?? 'Clicker Pro';
    final sub = user?.companyName?.isNotEmpty == true
        ? user!.companyName!
        : (user?.email ?? '');

    return Container(
      width: WebNavShell._sidebarWidth,
      padding: const EdgeInsets.only(top: 28, bottom: 26),
      decoration: BoxDecoration(
        color: WebTheme.chrome,
        borderRadius: BorderRadius.circular(WebTheme.rSidebar),
        boxShadow: WebTheme.sidebarShadow,
      ),
      // The nav pills bleed to the sidebar's right edge, so the rounded shell
      // must clip them.
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo row — tapping the brand always goes home ────────────
          WebEntrance(
            offset: 4,
            duration: const Duration(milliseconds: 420),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(RouteNames.dashboard),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: WebTheme.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('G',
                              style: WebTheme.displayStyle(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: WebTheme.chromeInk)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text.rich(
                        TextSpan(
                          text: 'Graphy',
                          style: WebTheme.displayStyle(
                              size: 19,
                              weight: FontWeight.w800,
                              color: WebTheme.chromeInk),
                          children: const [
                            TextSpan(
                              text: '7',
                              style: TextStyle(color: WebTheme.orangeLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Scrollable middle: profile + nav ─────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 14),
                _ProfileBlock(
                  initials: _initials(name),
                  name: name,
                  sub: sub,
                  email: user?.email ?? '',
                  roleLabel: _roleLabel(role),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < primary.length; i++)
                  WebEntrance(
                    delay: Duration(milliseconds: 24 * i),
                    offset: 5,
                    duration: const Duration(milliseconds: 340),
                    child: _NavPill(
                      dest: _labelOverride(primary[i]),
                      active: isActive(primary[i].route),
                      onTap: () => onTap(primary[i].route),
                    ),
                  ),
                if (more.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                    child: Text('MORE',
                        style: WebTheme.label(
                            size: 9,
                            color: WebTheme.amber,
                            tracking: 0.2)),
                  ),
                  for (final d in more)
                    _NavPill(
                      dest: d,
                      active: isActive(d.route),
                      onTap: () => onTap(d.route),
                      compact: true,
                    ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Active Team footer ───────────────────────────────────────
          _ActiveTeamFooter(onTap: () => onTap(RouteNames.team)),
        ],
      ),
    );
  }

  /// Freelancers see the Team destination as "My Companies" (handoff spec).
  _NavDest _labelOverride(_NavDest d) {
    if (d.route == RouteNames.team && role == UserRole.freelancer) {
      return _NavDest(Icons.business_rounded, 'My Companies',
          RouteNames.freelancerCompanies);
    }
    return d;
  }
}

/// Centered profile block: 92px gold-ring avatar, uppercase Sora name, muted
/// sub line, gold role badge pill. Bottom hairline per the handoff.
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({
    required this.initials,
    required this.name,
    required this.sub,
    required this.email,
    required this.roleLabel,
  });

  final String initials;
  final String name;
  final String sub;
  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WebTheme.chromeLine),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: WebTheme.amber.withValues(alpha: 0.6), width: 2),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: WebTheme.chromeAvatar,
              ),
              child: Center(
                child: Text(initials,
                    style: WebTheme.displayStyle(
                        size: 28,
                        weight: FontWeight.w700,
                        color: WebTheme.amber)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: WebTheme.display,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 16 * 0.06,
              color: WebTheme.chromeInk,
              decoration: TextDecoration.none,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: WebTheme.bodyStyle(
                  size: 10.5, color: WebTheme.chromeInkMuted),
            ),
          ],
          // Always surface the signed-in email so the user can confirm which
          // account they're on (same account works on web + mobile). Skipped
          // only when the line above already IS the email (no company name).
          if (email.isNotEmpty && email != sub) ...[
            const SizedBox(height: 3),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: WebTheme.bodyStyle(
                  size: 9.5, color: WebTheme.chromeInkMuted),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: WebTheme.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: WebTheme.amber.withValues(alpha: 0.35)),
            ),
            child: Text(roleLabel,
                style: WebTheme.label(
                    size: 9, color: WebTheme.amber, tracking: 0.14)),
          ),
        ],
      ),
    );
  }
}

/// One nav row in the handoff's pill language: 30px circled icon (gold border
/// inactive / orange active), uppercase Space-Mono-weight label, and an active
/// state that turns the row into a cream pill bleeding to the right edge
/// (border-radius 999 0 0 999).
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.dest,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  final _NavDest dest;
  final bool active;
  final VoidCallback onTap;

  /// "MORE" items render slightly tighter but in the same language.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dur = noMotion ? Duration.zero : WebTheme.base;

    return Padding(
      padding: EdgeInsets.only(left: 16, top: compact ? 2 : 4, bottom: compact ? 2 : 4),
      child: WebHoverHighlight(
        onTap: onTap,
        borderRadius: 999,
        builder: (context, hovering) {
          final Color labelColor = active
              ? WebTheme.ink
              : hovering
                  ? WebTheme.chromeInk
                  : WebTheme.chromeInkMuted;
          final Color iconColor = active
              ? WebTheme.orange
              : hovering
                  ? WebTheme.amber
                  : WebTheme.amber;
          final Color iconBorder = active
              ? WebTheme.orange.withValues(alpha: 0.35)
              : WebTheme.amber.withValues(alpha: 0.35);

          return AnimatedContainer(
            duration: dur,
            curve: WebTheme.ease,
            padding: EdgeInsets.fromLTRB(18, compact ? 7 : 9, 16, compact ? 7 : 9),
            decoration: BoxDecoration(
              color: active
                  ? WebTheme.pageBg
                  : hovering
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(999),
                bottomLeft: Radius.circular(999),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: dur,
                  curve: WebTheme.ease,
                  width: compact ? 26 : 30,
                  height: compact ? 26 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconBorder),
                  ),
                  child: Icon(dest.icon,
                      size: compact ? 12 : 14, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: dur,
                    curve: WebTheme.ease,
                    style: TextStyle(
                      fontFamily: WebTheme.body,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: (compact ? 10 : 11) * 0.16,
                      color: labelColor,
                      decoration: TextDecoration.none,
                    ),
                    child: Text(
                      dest.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "ACTIVE TEAM" gold label + overlapping 32px avatar stack + "+N" chip.
/// Reads the real team list; hides itself when there is none.
class _ActiveTeamFooter extends ConsumerWidget {
  const _ActiveTeamFooter({required this.onTap});
  final VoidCallback onTap;

  // A small rotation of tinted avatar palettes, matching the handoff's
  // hand-picked trio.
  static const List<({Color bg, Color fg})> _palettes = [
    (bg: Color(0xFF5C3A1E), fg: Color(0xFFF5B02E)),
    (bg: Color(0xFF4A2E3D), fg: Color(0xFFE8A0BF)),
    (bg: Color(0xFF2E4A3D), fg: Color(0xFF7ECFA8)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider).valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();

    final shown = members.take(3).toList();
    final extra = members.length - shown.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVE TEAM',
              style: WebTheme.label(
                  size: 9, color: WebTheme.amber, tracking: 0.2)),
          const SizedBox(height: 12),
          WebHoverHighlight(
            onTap: onTap,
            builder: (context, hovering) => Row(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Align(
                    widthFactor: i == 0 ? 1 : 0.75,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _palettes[i % _palettes.length].bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: WebTheme.chrome, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          shown[i].fullName.isEmpty
                              ? '?'
                              : shown[i].fullName[0].toUpperCase(),
                          style: WebTheme.bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _palettes[i % _palettes.length].fg,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (extra > 0)
                  Align(
                    widthFactor: 0.75,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: WebTheme.orange.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: WebTheme.chrome, width: 2),
                      ),
                      child: Center(
                        child: Text('+$extra',
                            style: WebTheme.label(
                                size: 9,
                                color: WebTheme.amber,
                                tracking: 0)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
