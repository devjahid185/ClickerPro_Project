// lib/shared/widgets/web_nav_shell.dart
//
// Clicker Pro — Web navigation shell (ClickerPro Design, premium).
//
// On wide web screens this wraps the routed app in a permanent left sidebar —
// a near-black chrome carrying the Signal-Orange brand mark, grouped nav with
// hover/active motion, and a profile footer — then renders the screen in a
// full-height warm-white content panel on the right. A slim top bar carries
// the page title and an orange tick. Chrome = near-black; action = orange.
//
//   • Mobile + narrow web are untouched (returns the child as-is).
//   • Auth / fullscreen routes (splash, login, register, onboarding, otp) get
//     NO sidebar — they render full-bleed.
//   • Nav items drive the real router via the root navigator key.
//   • All motion honours reduce-motion via the web_motion primitives.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/route_names.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/role/capability.dart';
import '../../core/role/role_policy.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/profile/application/profile_controllers.dart';
import '../../features/search/presentation/global_search_sheet.dart';
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
  /// `null` means everyone (Dashboard, Calendar, Settings, Profile…).
  final Capability? capability;
}

class _NavGroup {
  const _NavGroup(this.title, this.items);
  final String title;
  final List<_NavDest> items;
}

class WebNavShell extends ConsumerWidget {
  const WebNavShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  final Widget child;
  final String currentRoute;

  static const double _sidebarBreakpoint = 900;
  static const double _sidebarWidth = 256;

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
  };

  // Each destination carries the capability that gates it (null = everyone).
  // The same capabilities the mobile drawer uses, so web + mobile role
  // visibility stay in lockstep: a Freelancer never sees studio-management
  // surfaces (Finance, Team, Packages, Waitlist, Invoices, Reports…).
  // Web sidebar mirrors the mobile drawer 1:1 (same routes + same capability
  // gates) so every feature reachable on mobile is reachable on web —
  // "মোবাইল এপের সব ফিচার ওয়েব এপ এ থাকবে". Capability gates are copied from
  // dashboard_screen's drawer so role visibility stays in lockstep.
  static const List<_NavGroup> _groups = [
    _NavGroup('OVERVIEW', [
      _NavDest(Icons.dashboard_rounded, 'Dashboard', RouteNames.dashboard),
      _NavDest(Icons.calendar_month_rounded, 'Calendar', RouteNames.calendar),
    ]),
    _NavGroup('BOOKINGS', [
      _NavDest(Icons.event_note_rounded, 'Bookings', RouteNames.bookings),
      _NavDest(Icons.edit_note_rounded, 'Re-edit Requests',
          RouteNames.reEditRequests, capability: Capability.requestReEdit),
      _NavDest(Icons.inventory_2_rounded, 'Packages', RouteNames.packages,
          capability: Capability.accessPackages),
      _NavDest(Icons.hourglass_bottom_rounded, 'Waitlist', RouteNames.waitlist,
          capability: Capability.accessWaitlist),
    ]),
    _NavGroup('FINANCE', [
      _NavDest(Icons.account_balance_wallet_rounded, 'Finance',
          RouteNames.finance,
          capability: Capability.viewFinancials),
      _NavDest(Icons.receipt_long_rounded, 'Invoices', RouteNames.invoice,
          capability: Capability.accessInvoice),
      _NavDest(Icons.payments_rounded, 'Payments', RouteNames.paymentEntry,
          capability: Capability.viewBookingPayments),
      _NavDest(Icons.shopping_bag_rounded, 'Expenses',
          RouteNames.financeExpenses,
          capability: Capability.viewFinancials),
      _NavDest(Icons.account_balance_wallet_rounded, 'Payouts',
          RouteNames.teamSalarySheet,
          capability: Capability.viewFinancials),
      _NavDest(Icons.bar_chart_rounded, 'Reports', RouteNames.reports,
          capability: Capability.viewFinancials),
      _NavDest(Icons.insights_rounded, 'Performance', RouteNames.performance,
          capability: Capability.viewFinancials),
      _NavDest(Icons.timeline_rounded, 'Cash Flow', RouteNames.cashFlow,
          capability: Capability.viewFinancials),
    ]),
    _NavGroup('WORKSPACE', [
      _NavDest(Icons.groups_rounded, 'Team', RouteNames.team,
          capability: Capability.accessTeam),
      _NavDest(Icons.chat_bubble_rounded, 'Team Chat', RouteNames.chat),
      _NavDest(Icons.campaign_rounded, 'Announcements',
          RouteNames.announcements, capability: Capability.viewAnnouncements),
      _NavDest(Icons.cell_tower_rounded, 'Platform Updates',
          RouteNames.broadcasts),
    ]),
    _NavGroup('OPERATIONS', [
      _NavDest(Icons.camera_alt_rounded, 'Gear', RouteNames.gear),
      _NavDest(Icons.local_shipping_rounded, 'Delivery', RouteNames.delivery,
          capability: Capability.accessDelivery),
      _NavDest(Icons.follow_the_signs_rounded, 'Follow-up',
          RouteNames.followup, capability: Capability.accessFollowup),
      _NavDest(Icons.alarm_rounded, 'Reminders', RouteNames.reminders,
          capability: Capability.accessReminders),
      _NavDest(Icons.swap_horiz_rounded, 'Rent Tracking', RouteNames.rent,
          capability: Capability.accessRentTracking),
    ]),
    // Same offline utilities the mobile dashboard's quick-action row offers —
    // web/mobile feature parity ("ওয়েব এপ এ সব ফিচার সেইম সেইম থাকবে").
    _NavGroup('TOOLS', [
      _NavDest(Icons.calculate_rounded, 'Calculator', RouteNames.calculator),
      _NavDest(Icons.sticky_note_2_rounded, 'Notes', RouteNames.notes),
      _NavDest(Icons.calendar_month_rounded, 'Calendar Sync',
          RouteNames.calendarSyncSettings),
      _NavDest(Icons.settings_rounded, 'Settings', RouteNames.settings),
    ]),
  ];

  /// Filters [_groups] down to the destinations the given role may see, and
  /// drops any group left with no visible items.
  static List<_NavGroup> _visibleGroups(RolePolicy policy) {
    final out = <_NavGroup>[];
    for (final g in _groups) {
      final items = g.items
          .where((d) => d.capability == null || policy.can(d.capability!))
          .toList();
      if (items.isNotEmpty) out.add(_NavGroup(g.title, items));
    }
    return out;
  }

  bool _isActive(String route) {
    if (currentRoute == route) return true;
    if (route != '/' && currentRoute.startsWith('$route/')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar =
        width >= _sidebarBreakpoint && !_fullscreenRoutes.contains(currentRoute);

    if (!showSidebar) return child;

    // Role-gate the nav: a Freelancer (or any role) only sees the destinations
    // their RolePolicy allows, matching the mobile drawer's visibility.
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final policy = RolePolicy(role ?? UserRole.owner);
    final groups = _visibleGroups(policy);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Sidebar(
          groups: groups,
          isActive: _isActive,
          onTap: (route) {
            if (!_isActive(route)) {
              rootNavigatorKey.currentState?.pushNamed(route);
            }
          },
        ),
        // Full-height content panel: top bar + the routed screen.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopBar(),
              Expanded(
                // Re-key on route so each screen replays its entrance.
                child: WebEntrance(
                  key: ValueKey(currentRoute),
                  offset: 10,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── TOP BAR
/// The content-panel header, ported from the design source: a translucent
/// blurred bar carrying a search field, a Signal-Orange "New Booking" CTA, and
/// a notification bell with an unread dot. Search + bell are visual for now
/// (no backing behaviour yet); the CTA routes to Bookings.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        // Transparent Material so the header's Text never picks up the
        // "missing Material" underline, and taps get proper ink.
        child: Material(
          type: MaterialType.transparency,
          child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: const BoxDecoration(
            // Warm off-white at 85% so content faintly shows through the blur.
            color: Color(0xD9FBFAF7),
            border: Border(
              bottom: BorderSide(color: Color(0x0F000000), width: 1),
            ),
          ),
          child: Row(
            children: [
              _SearchField(onTap: _openGlobalSearch),
              const Spacer(),
              _NewBookingCta(
                onTap: () =>
                    rootNavigatorKey.currentState?.pushNamed(RouteNames.bookings),
              ),
              const SizedBox(width: 14),
              _NotificationBell(
                onTap: () => rootNavigatorKey.currentState
                    ?.pushNamed(RouteNames.notifications),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Search affordance (matches the design's 320px pill with a ⌘K hint). Tapping
/// opens the shared global search sheet — the same one the mobile app uses.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: 12,
      enableShadow: false,
      child: Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 19, color: Color(0xFFA3A199)),
          const SizedBox(width: 10),
          const Text(
            'Search anything…',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A988F),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(
              '⌘K',
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 10,
                color: const Color(0xFFB8B6AE),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// The orange primary action in the header.
class _NewBookingCta extends StatelessWidget {
  const _NewBookingCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: 11,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: WebTheme.orange,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: WebTheme.orange.withValues(alpha: 0.42),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'New Booking',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification bell with a small unread dot. Tapping opens the notifications
/// inbox — the same screen the mobile bell routes to.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: 11,
      enableShadow: false,
      child: SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WebTheme.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 21, color: Color(0xFF3A3A36)),
          ),
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: WebTheme.danger,
                shape: BoxShape.circle,
                border: Border.all(color: WebTheme.pageBg, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── SIDEBAR
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.groups,
    required this.isActive,
    required this.onTap,
  });

  final List<_NavGroup> groups;
  final bool Function(String) isActive;
  final ValueChanged<String> onTap;

  /// Builds the nav list (group headers + items) each wrapped in a staggered
  /// entrance. The delay grows per row but is capped so long rails don't crawl.
  List<Widget> _staggeredNav() {
    const step = Duration(milliseconds: 32);
    const cap = 16; // stop growing the delay after this many rows
    var i = 0;
    Widget staggered(Widget child) => WebEntrance(
          delay: step * (i < cap ? i++ : cap),
          offset: 6,
          duration: const Duration(milliseconds: 360),
          child: child,
        );

    final out = <Widget>[];
    for (final group in groups) {
      out.add(staggered(Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 7),
        child: Text(
          group.title.toUpperCase(),
          style: TextStyle(
            fontFamily: WebTheme.mono,
            fontSize: 9,
            letterSpacing: 1.8, // ≈0.2em at 9px
            fontWeight: FontWeight.w500,
            color: WebTheme.chromeInkFaint,
            decoration: TextDecoration.none,
          ),
        ),
      )));
      for (final dest in group.items) {
        out.add(staggered(_SidebarItem(
          dest: dest,
          active: isActive(dest.route),
          onTap: () => onTap(dest.route),
        )));
      }
    }
    out.add(const SizedBox(height: 12));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    // A transparent Material ancestor is REQUIRED: the sidebar lives outside the
    // routed screen's Scaffold, so without it every nav Text renders with the
    // "missing Material" yellow-underline debug decoration on web. It also gives
    // ink/splash a surface to paint on.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: WebNavShell._sidebarWidth,
        decoration: const BoxDecoration(
          // Near-black chrome with a whisper-soft top→foot gradient so the rail
          // reads as a crafted surface, not a flat block.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1815), WebTheme.chrome, Color(0xFF121110)],
            stops: [0.0, 0.5, 1.0],
          ),
          border: Border(
            right: BorderSide(color: WebTheme.chromeLine, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── Brand header ──────────────────────────────────────────────
          WebEntrance(
            offset: 4,
            duration: const Duration(milliseconds: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Graphy7 lockup (mark + wordmark) — the dark-surface PNG
                  // reads cleanly on the near-black chrome. Left-aligned, capped
                  // so it never crowds the 256px rail.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/brand/graphy7_lockup.png',
                      height: 34,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'PHOTOGRAPHY MANAGEMENT',
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.6, // ≈0.24em at 7.5px
                      color: WebTheme.chromeInkMuted,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable nav groups ─────────────────────────────────────
          // Items settle in with a gentle top-down stagger on first mount so
          // the rail assembles itself rather than snapping into place.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _staggeredNav(),
            ),
          ),

          const Divider(height: 1, color: WebTheme.chromeLine),

          // ── Footer (profile) ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: _SidebarItem(
              dest: const _NavDest(
                  Icons.person_rounded, 'Profile', RouteNames.profile),
              active: isActive(RouteNames.profile),
              onTap: () => onTap(RouteNames.profile),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// One nav row, richly animated. Active state is a glowing Signal-Orange pill;
/// hover is a faint white wash. A slim rounded accent bar slides in on the left
/// edge, and the icon nudges + scales — small, meaningful motion, all 60fps and
/// reduce-motion aware (the durations collapse to instant under disableAnimations).
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.dest,
    required this.active,
    required this.onTap,
  });

  final _NavDest dest;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Motion collapses to a hair when reduce-motion is on so the state still
    // updates but nothing visibly animates.
    final dur = noMotion ? Duration.zero : const Duration(milliseconds: 220);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: WebHoverHighlight(
        onTap: onTap,
        borderRadius: 12,
        builder: (context, hovering) {
          //   • active  → orange gradient pill + soft glow, white ink (w700)
          //   • hover   → faint white wash, ink brightens to chrome ink
          //   • default → muted chrome ink so the rail stays calm
          final Color fg = active
              ? Colors.white
              : hovering
                  ? WebTheme.chromeInk
                  : const Color(0xFFB8B4AC);
          final Color iconColor = active
              ? Colors.white
              : hovering
                  ? WebTheme.chromeInk
                  : const Color(0xFF8C877E);

          return AnimatedContainer(
            duration: dur,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9.5),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFF0772A), WebTheme.orange],
                    )
                  : null,
              color: active
                  ? null
                  : hovering
                      ? Colors.white.withValues(alpha: 0.055)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active && !noMotion
                  ? [
                      BoxShadow(
                        color: WebTheme.orange.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                // Slim accent rail on the left — grows in when active, a faint
                // stub on hover, gone at rest. The whole row's motion anchor.
                AnimatedContainer(
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  width: 3,
                  height: active ? 16 : (hovering ? 9 : 0),
                  margin: EdgeInsets.only(right: active || hovering ? 8 : 11),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.9)
                        : WebTheme.orange.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon nudges + scales a touch on active for a tactile feel.
                AnimatedScale(
                  duration: dur,
                  curve: Curves.easeOutBack,
                  scale: active ? 1.08 : 1.0,
                  child: Icon(dest.icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: dur,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.14, // ≈-0.01em
                      color: fg,
                      // Explicitly kill any inherited underline/decoration.
                      decoration: TextDecoration.none,
                    ),
                    child: Text(
                      dest.label,
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
