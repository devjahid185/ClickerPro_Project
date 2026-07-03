// lib/shared/widgets/web_nav_shell.dart
//
// Clicker Pro — Web navigation shell (v18 "Studio Sage", premium).
//
// On wide web screens this wraps the routed app in a permanent left sidebar —
// a calm sage-green chrome carrying the orange brand mark, grouped nav with
// hover/active motion, and a profile footer — then renders the screen in a
// full-height white content panel on the right. A slim top bar carries the
// page title and a sage tick. Chrome = sage; action = orange.
//
//   • Mobile + narrow web are untouched (returns the child as-is).
//   • Auth / fullscreen routes (splash, login, register, onboarding, otp) get
//     NO sidebar — they render full-bleed.
//   • Nav items drive the real router via the root navigator key.
//   • All motion honours reduce-motion via the web_motion primitives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/route_names.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/role/capability.dart';
import '../../core/role/role_policy.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/profile/application/profile_controllers.dart';
import '../../theme/web_theme.dart';
import 'web_motion.dart';

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
  static const double _sidebarWidth = 264;

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
  static const List<_NavGroup> _groups = [
    _NavGroup('OVERVIEW', [
      _NavDest(Icons.dashboard_rounded, 'Dashboard', RouteNames.dashboard),
      _NavDest(Icons.calendar_month_rounded, 'Calendar', RouteNames.calendar),
    ]),
    _NavGroup('BOOKINGS', [
      _NavDest(Icons.event_note_rounded, 'Bookings', RouteNames.bookings),
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
      _NavDest(Icons.bar_chart_rounded, 'Reports', RouteNames.reports,
          capability: Capability.viewFinancials),
    ]),
    _NavGroup('WORKSPACE', [
      _NavDest(Icons.groups_rounded, 'Team', RouteNames.team,
          capability: Capability.accessTeam),
      _NavDest(Icons.camera_alt_rounded, 'Gear', RouteNames.gear),
      _NavDest(Icons.settings_rounded, 'Settings', RouteNames.settings),
    ]),
    // Same offline utilities the mobile dashboard's quick-action row offers —
    // web/mobile feature parity ("ওয়েব এপ এ সব ফিচার সেইম সেইম থাকবে").
    _NavGroup('TOOLS', [
      _NavDest(Icons.mosque_rounded, 'Prayer Times', RouteNames.prayerTimes),
      _NavDest(Icons.calculate_rounded, 'Calculator', RouteNames.calculator),
      _NavDest(Icons.sticky_note_2_rounded, 'Notes', RouteNames.notes),
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

  /// Human title for the current route, shown in the top bar.
  String _titleFor() {
    for (final g in _groups) {
      for (final d in g.items) {
        if (_isActive(d.route)) return d.label;
      }
    }
    if (_isActive(RouteNames.profile)) return 'Profile';
    return 'Clicker Pro';
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
              _TopBar(title: _titleFor()),
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
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: WebTheme.sp5),
      decoration: const BoxDecoration(
        color: WebTheme.surface,
        border: Border(
          bottom: BorderSide(color: WebTheme.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // A small sunset tick before the title for brand consistency.
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: WebTheme.sunset,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
            ),
          ),
          const SizedBox(width: WebTheme.sp3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: WebTheme.ink,
            ),
          ),
          const Spacer(),
          // Decorative "live" pill — warm, subtle, reads as a healthy app.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: WebTheme.successSoft,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: WebTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.success,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WebNavShell._sidebarWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WebTheme.sidebar, WebTheme.sidebarDeep],
        ),
        border: Border(
          right: BorderSide(color: WebTheme.sageLine, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Brand header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: WebTheme.sunset,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: WebTheme.orange.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Clicker Pro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: WebTheme.ink,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Studio Suite',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: WebTheme.sageMid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable nav groups ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.sageMid,
                      ),
                    ),
                  ),
                  for (final dest in group.items)
                    _SidebarItem(
                      dest: dest,
                      active: isActive(dest.route),
                      onTap: () => onTap(dest.route),
                    ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          const Divider(height: 1, color: WebTheme.sageLine),

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
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: WebHoverHighlight(
        onTap: onTap,
        borderRadius: WebTheme.rButton,
        builder: (context, hovering) {
          // Chrome = sage. Active = crisp white pill with a sage shadow (lifts
          // off the green sidebar) + an orange accent bar (action). Hover =
          // faint sage tint. This keeps the green calm and the orange loud.
          final Color bg = active
              ? Colors.white
              : hovering
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.transparent;
          final Color fg = active
              ? WebTheme.sageDark
              : hovering
                  ? WebTheme.sageDeep
                  : WebTheme.inkSoft;
          final Color iconColor = active ? WebTheme.orange : fg;

          return AnimatedContainer(
            duration: WebTheme.fast,
            curve: WebTheme.ease,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(WebTheme.rButton),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x145B7B6A),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Active accent bar — orange (action), slides in via width.
                AnimatedContainer(
                  duration: WebTheme.base,
                  curve: WebTheme.ease,
                  width: active ? 3 : 0,
                  height: 18,
                  margin: EdgeInsets.only(right: active ? 9 : 0),
                  decoration: BoxDecoration(
                    gradient: WebTheme.sunset,
                    borderRadius: BorderRadius.circular(WebTheme.rFull),
                  ),
                ),
                Icon(dest.icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  dest.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
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
