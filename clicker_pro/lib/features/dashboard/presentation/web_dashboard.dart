// lib/features/dashboard/presentation/web_dashboard.dart
//
// Clicker Pro — WEB-ONLY dashboard (ClickerPro Design).
//
// A proper desktop dashboard layout, rendered ONLY on wide web. The mobile
// dashboard body is 100% untouched (DashboardScreen routes to this widget only
// when kIsWeb && width >= 900). Structure — near-black sidebar chrome (in
// WebNavShell), Signal Orange action, warm off-white cards — laid out as:
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │  Greeting header  +  primary CTA (New Booking, orange)        │
//   ├──────────────────────────────────────────────────────────────┤
//   │  KPI row: Today · Upcoming · Collection · Due   (role-aware)  │
//   ├──────────────────────────────────┬───────────────────────────┤
//   │  Performance card (weekly bars)  │  Quick actions            │
//   │  Recent bookings table           │  Announcement             │
//   │                                  │  This month (info)        │
//   └──────────────────────────────────┴───────────────────────────┘
//
// All data comes from the same providers the mobile dashboard already uses, so
// there is no new business logic — only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/format/booking_format.dart';
import '../../../core/format/currency.dart';
import '../../../core/navigation/route_names.dart';
import '../../../theme/web_theme.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../auth/domain/user_role.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/event_type_vibe.dart';
import '../../announcements/application/announcement_providers.dart';
import '../../profile/domain/user_model.dart';
import '../application/dashboard_providers.dart';

/// The wide-web dashboard. Pure presentation over the existing providers.
class WebDashboard extends ConsumerWidget {
  const WebDashboard({super.key, this.user});

  final UserModel? user;

  /// Below this the page switches to a single stacked column.
  static const double _twoColBreakpoint = 1180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final twoCol = width >= _twoColBreakpoint;

    // Max content width keeps cards from stretching on ultra-wide monitors.
    final maxW = width.clamp(0, 1480).toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(child: _Header(user: user)),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: _KpiRow(user: user),
            ),
            const SizedBox(height: WebTheme.sp5),
            if (twoCol)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 62,
                      child: WebEntrance(
                        delay: const Duration(milliseconds: 110),
                        child: _MainColumn(user: user),
                      ),
                    ),
                    const SizedBox(width: WebTheme.sp5),
                    Expanded(
                      flex: 38,
                      child: WebEntrance(
                        delay: const Duration(milliseconds: 165),
                        child: _SideColumn(user: user),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              WebEntrance(
                delay: const Duration(milliseconds: 110),
                child: _MainColumn(user: user),
              ),
              const SizedBox(height: WebTheme.sp5),
              WebEntrance(
                delay: const Duration(milliseconds: 165),
                child: _SideColumn(user: user),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({this.user});
  final UserModel? user;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'there';
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $name 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: WebTheme.ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your studio at a glance · $today",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: WebTheme.sp4),
        _PrimaryCta(
          label: 'New Booking',
          icon: Icons.add_rounded,
          onTap: () => Navigator.of(context).pushNamed(RouteNames.bookings),
        ),
      ],
    );
  }
}

/// Orange (action) pill button — the only loud element in the header.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rButton,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: WebTheme.sunset,
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          boxShadow: [
            BoxShadow(
              color: WebTheme.orange.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── KPI ROW
class _KpiRow extends ConsumerWidget {
  const _KpiRow({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final m = metricsAsync.value ?? DashboardMetrics.placeholder;
    final loading = metricsAsync.isLoading && metricsAsync.value == null;

    final role = user?.role ?? UserRole.owner;
    final isFreelancer = role == UserRole.freelancer;
    final isManager = role == UserRole.manager;

    // Finance labels are role-aware (same logic as mobile dashboard).
    final collectLabel = isFreelancer ? 'Received Today' : "Today's Collection";
    final dueLabel = isFreelancer ? 'Pending Payout' : 'Pending Due';

    final cards = <Widget>[
      _KpiCard(
        label: "Today's Events",
        value: '${m.todayEvents}',
        sub: '${m.todayDayEvents} day · ${m.todayNightEvents} night',
        icon: Icons.event_available_rounded,
        accent: WebTheme.sage,
        loading: loading,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.bookings),
      ),
      _KpiCard(
        label: 'Upcoming',
        value: '${m.upcomingEvents}',
        sub: '${m.totalEvents} total booked',
        icon: Icons.upcoming_rounded,
        accent: WebTheme.info,
        loading: loading,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.calendar),
      ),
    ];

    // Collection only for Owner/Both/Freelancer (managers don't see income).
    if (!isManager) {
      cards.add(
        _KpiCard(
          label: collectLabel,
          value: _formatBdt(m.todayCollection),
          sub: 'across paid events',
          icon: Icons.payments_rounded,
          accent: WebTheme.success,
          loading: loading,
          onTap: () => Navigator.of(context).pushNamed(RouteNames.finance),
        ),
      );
    }

    cards.add(
      _KpiCard(
        label: dueLabel,
        value: _formatBdt(m.pendingDue),
        sub: 'outstanding',
        icon: Icons.hourglass_bottom_rounded,
        accent: WebTheme.orange,
        loading: loading,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.finance),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two-up below ~900 content width, else a single equal row.
        final narrow = constraints.maxWidth < 760;
        if (narrow) {
          return Wrap(
            spacing: WebTheme.sp4,
            runSpacing: WebTheme.sp4,
            children: [
              for (final c in cards)
                SizedBox(
                  width: (constraints.maxWidth - WebTheme.sp4) / 2,
                  child: c,
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: WebTheme.sp4),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accent,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color accent;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rCard,
      child: Container(
        padding: const EdgeInsets.all(WebTheme.sp5),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          border: Border.all(color: WebTheme.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WebTheme.rChip),
                  ),
                  child: Icon(icon, color: accent, size: 21),
                ),
                const Spacer(),
                Icon(Icons.north_east_rounded,
                    size: 16, color: WebTheme.inkFaint),
              ],
            ),
            const SizedBox(height: WebTheme.sp4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: WebTheme.inkMuted,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            loading
                ? const _ValueShimmer()
                : Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: WebTheme.ink,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
            const SizedBox(height: 6),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueShimmer extends StatelessWidget {
  const _ValueShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 84,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: WebTheme.sageTintSoft,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── MAIN COLUMN
class _MainColumn extends ConsumerWidget {
  const _MainColumn({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _PerformanceCard(),
        SizedBox(height: WebTheme.sp5),
        _RecentBookingsCard(),
      ],
    );
  }
}

/// A weekly delivered/booked snapshot with a simple, clean bar chart.
class _PerformanceCard extends ConsumerWidget {
  const _PerformanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final m = metricsAsync.value ?? DashboardMetrics.placeholder;

    // Build this-week per-day booking counts from the live month stream.
    final now = DateTime.now();
    final monthAsync = ref.watch(
      calendarBookingsProvider((year: now.year, month: now.month)),
    );
    final bookings = monthAsync.value ?? const <Booking>[];

    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekCounts = List<int>.filled(7, 0);
    for (final b in bookings) {
      final d = DateTime(b.date.year, b.date.month, b.date.day);
      final diff = d.difference(monday).inDays;
      if (diff >= 0 && diff < 7) weekCounts[diff]++;
    }
    final maxCount =
        weekCounts.isEmpty ? 1 : (weekCounts.reduce((a, b) => a > b ? a : b));
    const dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'This Week',
            subtitle: 'Bookings per day',
            trailing: _StatPill(
              icon: Icons.check_circle_rounded,
              label: '${m.successEvents} delivered',
              color: WebTheme.success,
            ),
          ),
          const SizedBox(height: WebTheme.sp5),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = weekCounts[i];
                final isToday = i == (today.weekday - 1);
                final frac = maxCount == 0 ? 0.0 : count / maxCount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count == 0 ? '' : '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isToday ? WebTheme.orange : WebTheme.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Animated bar: grows from 8px → full on mount.
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: frac),
                          duration: WebTheme.slow,
                          curve: WebTheme.ease,
                          builder: (context, v, _) {
                            final h = 8.0 + v * 96.0;
                            return Container(
                              height: h,
                              decoration: BoxDecoration(
                                gradient: isToday
                                    ? WebTheme.sunset
                                    : const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          WebTheme.sage,
                                          WebTheme.sageDeep,
                                        ],
                                      ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dow[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isToday ? WebTheme.ink : WebTheme.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// The recent / upcoming bookings table — the heart of the dashboard.
class _RecentBookingsCard extends ConsumerWidget {
  const _RecentBookingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthAsync = ref.watch(
      calendarBookingsProvider((year: now.year, month: now.month)),
    );

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Upcoming Bookings',
            subtitle: 'Sorted by date',
            trailing: _ViewAll(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.bookings),
            ),
          ),
          const SizedBox(height: WebTheme.sp3),
          monthAsync.when(
            loading: () => const _TableSkeleton(),
            error: (_, _) => const _TableEmpty(
              message: 'Could not load bookings.',
            ),
            data: (all) {
              final today = DateTime(now.year, now.month, now.day);
              final upcoming = all
                  .where((b) {
                    final d = DateTime(b.date.year, b.date.month, b.date.day);
                    return !d.isBefore(today);
                  })
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
              final rows = upcoming.take(6).toList();
              if (rows.isEmpty) {
                return const _TableEmpty(
                  message: 'No upcoming bookings this month.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: WebTheme.hairline),
                    _BookingRow(booking: rows[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});
  final Booking booking;

  String _statusLabel(String raw) {
    // Turn enum name (e.g. inProgress) into Title Case ("In Progress").
    final spaced = raw.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]}',
    );
    final t = spaced.trim();
    return t.isEmpty ? raw : '${t[0].toUpperCase()}${t.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final vibe = booking.eventType.vibe;
    final client = (booking.clientName?.trim().isNotEmpty ?? false)
        ? booking.clientName!.trim()
        : booking.title;
    final dateStr = DateFormat('d MMM').format(booking.date);
    final statusColor = WebTheme.statusColor(booking.status.name);
    final price = booking.customPrice;

    return WebHoverHighlight(
      borderRadius: WebTheme.rChip,
      onTap: () => Navigator.of(context).pushNamed(
        RouteNames.bookingDetail,
        arguments: booking.id,
      ),
      builder: (context, hovering) {
        return AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.sp3,
            vertical: WebTheme.sp3,
          ),
          decoration: BoxDecoration(
            color: hovering ? WebTheme.sageTintSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(WebTheme.rChip),
          ),
          child: Row(
            children: [
              // Event-type vibe avatar.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: vibe.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(WebTheme.rChip),
                ),
                child: Icon(vibe.icon, color: vibe.color, size: 20),
              ),
              const SizedBox(width: WebTheme.sp3),
              // Client + event type.
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: WebTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vibe.label} · ${BookingFormat.clockTime(booking.startTime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: WebTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Date.
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.inkSoft,
                  ),
                ),
              ),
              // Status badge.
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WebTheme.rFull),
                    ),
                    child: Text(
                      _statusLabel(booking.status.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Price (right-aligned).
              Expanded(
                flex: 2,
                child: Text(
                  price == null ? '—' : _formatBdt((price * 100).round()),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────── SIDE COLUMN
class _SideColumn extends ConsumerWidget {
  const _SideColumn({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActionsCard(user: user),
        const SizedBox(height: WebTheme.sp5),
        const _AnnouncementCard(),
        const SizedBox(height: WebTheme.sp5),
        const _ThisMonthCard(),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final isFreelancer = user?.role == UserRole.freelancer;
    final actions = <_Qa>[
      _Qa(Icons.calendar_month_rounded, 'Calendar', WebTheme.sage,
          RouteNames.calendar),
      _Qa(
        isFreelancer ? Icons.business_rounded : Icons.receipt_long_rounded,
        isFreelancer ? 'Company' : 'Invoice',
        WebTheme.info,
        isFreelancer ? RouteNames.bookings : RouteNames.invoice,
      ),
      _Qa(Icons.inventory_2_rounded, 'Packages', WebTheme.success,
          RouteNames.packages),
      _Qa(Icons.groups_rounded, 'Team', WebTheme.orange, RouteNames.team),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'Quick Actions'),
          const SizedBox(height: WebTheme.sp4),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: WebTheme.sp3,
            crossAxisSpacing: WebTheme.sp3,
            childAspectRatio: 2.4,
            children: [
              for (final a in actions)
                WebHoverLift(
                  onTap: () => Navigator.of(context).pushNamed(a.route),
                  borderRadius: WebTheme.rChip,
                  enableShadow: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: WebTheme.sageTintSoft,
                      borderRadius: BorderRadius.circular(WebTheme.rChip),
                      border: Border.all(color: WebTheme.sageLine),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(a.icon, color: a.color, size: 17),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            a.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: WebTheme.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Qa {
  const _Qa(this.icon, this.label, this.color, this.route);
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _AnnouncementCard extends ConsumerWidget {
  const _AnnouncementCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(sortedAnnouncementsProvider);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Announcement',
            trailing: _ViewAll(
              onTap: () => Navigator.of(context)
                  .pushNamed(RouteNames.announcements),
            ),
          ),
          const SizedBox(height: WebTheme.sp4),
          announcementsAsync.when(
            loading: () => const _AnnouncementBody(
              text: 'Loading announcements…',
            ),
            error: (_, _) => const _AnnouncementBody(
              text: 'Could not load announcements.',
            ),
            data: (items) {
              final active = items.where((a) => !a.isExpired).toList();
              if (active.isEmpty) {
                return const _AnnouncementBody(
                  text: 'No announcements yet — tap "View all" to post one.',
                );
              }
              final a = active.first;
              return _AnnouncementBody(title: a.title, text: a.body);
            },
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBody extends StatelessWidget {
  const _AnnouncementBody({this.title, required this.text});
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WebTheme.sp4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebTheme.orange.withValues(alpha: 0.08),
            WebTheme.amber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(WebTheme.rChip),
        border: Border.all(color: WebTheme.orange.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: WebTheme.sunset,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: WebTheme.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title?.trim().isNotEmpty ?? false) ...[
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: WebTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkSoft,
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

class _ThisMonthCard extends ConsumerWidget {
  const _ThisMonthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final m = metricsAsync.value ?? DashboardMetrics.placeholder;
    final monthName = DateFormat.MMMM().format(DateTime.now());
    // National gazetted days first (most relevant), then weekly Fri/Sat.
    final all = bdHolidaysOfMonth(DateTime.now());
    final national =
        all.where((h) => !h.name.startsWith('Weekly Holiday')).toList();
    final weekly =
        all.where((h) => h.name.startsWith('Weekly Holiday')).toList();
    final holidays = [...national, ...weekly];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: monthName, subtitle: 'This month'),
          const SizedBox(height: WebTheme.sp4),
          _InfoRow(
            icon: Icons.celebration_rounded,
            color: WebTheme.amberDeep,
            label: 'Holidays',
            value: '${m.holidaysThisMonth}',
          ),
          const SizedBox(height: WebTheme.sp3),
          _InfoRow(
            icon: Icons.cancel_rounded,
            color: WebTheme.danger,
            label: 'Cancelled events',
            value: '${m.cancelledEvents}',
          ),
          if (holidays.isNotEmpty) ...[
            const SizedBox(height: WebTheme.sp4),
            const Divider(height: 1, color: WebTheme.hairline),
            const SizedBox(height: WebTheme.sp3),
            for (final h in holidays.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: WebTheme.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${h.date.day}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: WebTheme.amberDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: WebTheme.sp3),
                    Expanded(
                      child: Text(
                        h.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: WebTheme.sp3),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: WebTheme.inkSoft,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── SHARED BUILDING BLOCKS
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.sp5),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: WebTheme.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WebTheme.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAll extends StatelessWidget {
  const _ViewAll({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      borderRadius: WebTheme.rFull,
      onTap: onTap,
      builder: (context, hovering) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: hovering ? WebTheme.sageTint : Colors.transparent,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.sage,
                ),
              ),
              SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded,
                  size: 17, color: WebTheme.sage),
            ],
          ),
        );
      },
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: WebTheme.sp3),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WebTheme.sageTintSoft,
                  borderRadius: BorderRadius.circular(WebTheme.rChip),
                ),
              ),
              const SizedBox(width: WebTheme.sp3),
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: WebTheme.sageTintSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableEmpty extends StatelessWidget {
  const _TableEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WebTheme.sp6),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: const Icon(Icons.event_busy_rounded,
                  color: WebTheme.sage, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
/// Compact active-currency formatter (paisa → symbol with South-Asian
/// grouping). Mirrors the mobile dashboard's formatter so totals read
/// identically across platforms.
String _formatBdt(int minor) {
  final taka = (minor / 100).round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}
