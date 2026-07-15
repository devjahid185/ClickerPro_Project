// lib/features/dashboard/presentation/web_dashboard.dart
//
// Clicker Pro — WEB-ONLY dashboard (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 1).
//
// Rendered ONLY on wide web (DashboardScreen routes here when kIsWeb &&
// width >= 900); the mobile dashboard body is 100% untouched. Layout follows
// the handoff exactly — main column + a 316px right panel that exists ONLY on
// this screen:
//
//   main column                          right panel (316px)
//   ┌──────────────────────────────┐     ┌──────────────────────┐
//   │ Week strip (7 day cards)      │     │ Finance · month      │
//   │ Split hero (03 + 2 stats)     │     │  (role-aware)        │
//   │ Delivered strip (mini bars)   │     │ Announcement (dark)  │
//   │ Today's Bookings rows         │     │ Mini calendar        │
//   │ Quick actions (4)             │     └──────────────────────┘
//   └──────────────────────────────┘
//
// All data comes from the same providers the mobile dashboard already uses —
// no new business logic, only the web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/bd_holidays.dart';
import '../../../core/format/currency.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../../announcements/application/announcement_providers.dart';
import '../../auth/domain/user_role.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../bookings/domain/event_type_vibe.dart';
import '../../bookings/domain/shift.dart';
import '../../profile/domain/user_model.dart';
import '../application/dashboard_providers.dart';

/// The wide-web dashboard. Pure presentation over the existing providers.
class WebDashboard extends ConsumerWidget {
  const WebDashboard({super.key, this.user});

  final UserModel? user;

  /// Below this the right panel stacks under the main column.
  static const double _panelBreakpoint = 1180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final sideBySide = width >= _panelBreakpoint;

    final main = _MainColumn(user: user);
    final panel = _RightPanel(user: user);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: main),
                  const SizedBox(width: 20),
                  SizedBox(width: 316, child: panel),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [main, const SizedBox(height: 18), panel],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════ MAIN COLUMN
class _MainColumn extends StatelessWidget {
  const _MainColumn({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? UserRole.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebEntrance(
          delay: const Duration(milliseconds: 50),
          child: const _WeekStrip(),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 100),
          child: const _SplitHero(),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 150),
          child: const _DeliveredStrip(),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 200),
          child: const _TodaysBookingsCard(),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 250),
          child: _QuickActions(role: role),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── WEEK STRIP
/// 7 equal day cards: DOW, date number, up to 3 event pips (gold=day shift,
/// purple=night). Today = orange with glow. Hover lifts −3px.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i != 0) const SizedBox(width: 10),
          Expanded(
            child: _WeekDayCard(
              date: monday.add(Duration(days: i)),
              today: today,
              bookings: bookings,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.today,
    required this.bookings,
  });

  final DateTime date;
  final DateTime today;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final isToday = date == today;
    final dayEvents = bookings.where((b) {
      if (b.status == BookingStatus.cancelled) return false;
      return b.date.year == date.year &&
          b.date.month == date.month &&
          b.date.day == date.day;
    }).toList();

    final pips = <Color>[
      for (final b in dayEvents.take(3))
        b.shift == Shift.night
            ? (isToday ? WebTheme.chrome : WebTheme.night)
            : (isToday ? WebTheme.chromeInk : WebTheme.amber),
    ];

    return _HoverTranslate(
      dy: -3,
      onTap: () => Navigator.of(context).pushNamed(RouteNames.calendar),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isToday ? WebTheme.orange : WebTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isToday ? WebTheme.orange : WebTheme.hairline),
          boxShadow: isToday ? WebTheme.buttonGlow : WebTheme.cardShadowSmall,
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE').format(date).toUpperCase(),
              style: WebTheme.label(
                size: 9,
                tracking: 0.12,
                color:
                    isToday ? WebTheme.onOrangeLabel : WebTheme.inkMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: WebTheme.displayStyle(
                size: 20,
                weight: FontWeight.w800,
                color: isToday ? WebTheme.chromeInk : WebTheme.ink,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pips.length; i++) ...[
                    if (i != 0) const SizedBox(width: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: pips[i], shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── SPLIT HERO
/// Left: orange gradient hero with the giant today-count (pop-in) + shift
/// legend + "Next: …" line. Right: UPCOMING and TOTAL BOOKINGS stat cards.
class _SplitHero extends ConsumerWidget {
  const _SplitHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(dashboardMetricsProvider).valueOrNull ??
        DashboardMetrics.placeholder;
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];

    final now = DateTime.now();
    final thisMonth = bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            b.date.year == now.year &&
            b.date.month == now.month)
        .length;

    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 640;
      // Tapping the hero opens today's bookings — same as the mobile
      // dashboard's today card (parity: "মোবাইল এপের ফিচার যা কাজ করে ওয়েব
      // এপ ও সেই কাজ করবে").
      final hero = _HoverTranslate(
        dy: -2,
        onTap: () => DashboardNav.openToday(ref, context),
        child: _HeroCard(metrics: m, next: _nextEvent(bookings)),
      );
      final stats = Column(
        children: [
          Expanded(
            child: _StatCard(
              label: 'UPCOMING',
              value: '${m.upcomingEvents}',
              valueColor: WebTheme.orange,
              sub: 'scheduled ahead',
              subColor: WebTheme.inkMuted,
              onTap: () => DashboardNav.openUpcoming(ref, context),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _StatCard(
              label: 'TOTAL BOOKINGS',
              value: '${m.totalEvents}',
              valueColor: WebTheme.ink,
              sub: '↑ $thisMonth this month',
              subColor: WebTheme.success,
              onTap: () => DashboardNav.openAll(ref, context),
            ),
          ),
        ],
      );

      if (narrow) {
        return Column(children: [
          hero,
          const SizedBox(height: 18),
          SizedBox(height: 220, child: stats),
        ]);
      }
      return SizedBox(
        height: 236,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: hero),
            const SizedBox(width: 18),
            Expanded(flex: 2, child: stats),
          ],
        ),
      );
    });
  }

  /// The next event line: today's next booking (by start time), else the
  /// nearest future booking.
  static Booking? _nextEvent(List<Booking> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            !DateTime(b.date.year, b.date.month, b.date.day)
                .isBefore(today))
        .toList()
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        return a.startTime.compareTo(b.startTime);
      });
    return active.isEmpty ? null : active.first;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.metrics, required this.next});
  final DashboardMetrics metrics;
  final Booking? next;

  @override
  Widget build(BuildContext context) {
    final nextLine = next == null
        ? 'No upcoming events — enjoy the calm ✨'
        : 'Next: ${next!.eventType.vibe.label}'
            '${next!.venue?.isNotEmpty == true ? ' — ${next!.venue}' : ''}'
            ' · reporting ${_time12(next!.startTime)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: WebTheme.sunset,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        boxShadow: WebTheme.orangeGlow,
      ),
      child: Stack(
        children: [
          // Blurred gold glow blob, top-right (radial stands in for blur 90).
          Positioned(
            top: -80,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    WebTheme.amber.withValues(alpha: 0.35),
                    WebTheme.amber.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TODAY'S EVENTS",
                  style: WebTheme.label(
                      size: 9,
                      color: WebTheme.onOrangeLabel,
                      tracking: 0.25)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PopIn(
                      delay: const Duration(milliseconds: 250),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          metrics.todayEvents.toString().padLeft(2, '0'),
                          style: WebTheme.displayStyle(
                            size: 96,
                            weight: FontWeight.w800,
                            color: WebTheme.chromeInk,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legend(WebTheme.amber,
                              '${metrics.todayDayEvents} Day shift'),
                          const SizedBox(height: 8),
                          _legend(WebTheme.chrome,
                              '${metrics.todayNightEvents} Night shift'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                nextLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WebTheme.bodyStyle(
                    size: 12, color: WebTheme.onOrangeLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color dot, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text,
            style:
                WebTheme.bodyStyle(size: 12.5, color: WebTheme.onOrangeBody)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
    required this.subColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String sub;
  final Color subColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _HoverTranslate(
      dy: -2,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: WebTheme.label(
                    size: 9, color: WebTheme.inkMuted, tracking: 0.2)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: WebTheme.displayStyle(
                        size: 38,
                        weight: FontWeight.w800,
                        color: valueColor)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(size: 11, color: subColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── DELIVERED STRIP
/// "DELIVERED / N" + 7 mini month bars (last bar orange→gold) + range/delta.
class _DeliveredStrip extends ConsumerWidget {
  const _DeliveredStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(dashboardMetricsProvider).valueOrNull ??
        DashboardMetrics.placeholder;
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];

    // Delivered/completed/shot counts per month, oldest → current, 7 months.
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);
    for (final b in bookings) {
      if (b.status != BookingStatus.completed &&
          b.status != BookingStatus.delivered &&
          b.status != BookingStatus.shotComplete) {
        continue;
      }
      final diff =
          (now.year - b.date.year) * 12 + (now.month - b.date.month);
      if (diff < 0 || diff > 6) continue;
      counts[6 - diff]++;
    }
    final maxCount =
        counts.fold<int>(1, (mx, c) => c > mx ? c : mx);

    final firstMonth = DateTime(now.year, now.month - 6);
    final range =
        '${DateFormat('MMM').format(firstMonth).toUpperCase()} – '
        '${DateFormat('MMM').format(now).toUpperCase()}';
    final prev = counts[5];
    final last = counts[6];
    final deltaPct =
        prev > 0 ? (((last - prev) / prev) * 100).round() : null;

    return _HoverTranslate(
      dy: -2,
      onTap: () => DashboardNav.openDelivered(ref, context),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELIVERED',
                  style: WebTheme.label(
                      size: 9, color: WebTheme.inkMuted, tracking: 0.2)),
              Text('${m.successEvents}',
                  style: WebTheme.displayStyle(
                      size: 34,
                      weight: FontWeight.w800,
                      color: WebTheme.success,
                      height: 1.1)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < counts.length; i++) ...[
                    if (i != 0) const SizedBox(width: 6),
                    Expanded(
                      child: _GrowBar(
                        delay: Duration(milliseconds: 60 * i),
                        heightFraction:
                            (counts[i] / maxCount).clamp(0.12, 1.0),
                        maxHeight: 44,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                              bottom: Radius.circular(2)),
                          gradient:
                              i == counts.length - 1 ? WebTheme.barGradient : null,
                          color: i == counts.length - 1
                              ? null
                              : WebTheme.orange.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(range,
                  style: WebTheme.label(
                      size: 10, color: WebTheme.inkMuted, tracking: 0.08)),
              const SizedBox(height: 6),
              Text(
                deltaPct == null
                    ? '—'
                    : '${deltaPct >= 0 ? '▲' : '▼'} ${deltaPct.abs()}%',
                style: WebTheme.label(
                    size: 10,
                    color: deltaPct != null && deltaPct >= 0
                        ? WebTheme.success
                        : WebTheme.inkMuted,
                    tracking: 0.08),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── TODAY'S BOOKINGS
class _TodaysBookingsCard extends ConsumerWidget {
  const _TodaysBookingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];
    final dues = ref.watch(dueBreakdownProvider).valueOrNull ??
        const <DueEntry>[];
    final dueByBooking = {for (final d in dues) d.bookingId: d.due};

    final now = DateTime.now();
    final todays = bookings.where((b) {
      if (b.status == BookingStatus.cancelled) return false;
      return b.date.year == now.year &&
          b.date.month == now.month &&
          b.date.day == now.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("Today's Bookings",
                  style: WebTheme.displayStyle(size: 17)),
              const Spacer(),
              _MonoLink(
                label: 'VIEW ALL →',
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteNames.bookings),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'No bookings today.',
                textAlign: TextAlign.center,
                style:
                    WebTheme.bodyStyle(size: 12.5, color: WebTheme.inkMuted),
              ),
            )
          else
            for (var i = 0; i < todays.length; i++) ...[
              if (i != 0) const SizedBox(height: 10),
              WebEntrance(
                delay: Duration(milliseconds: 60 * i),
                offset: 6,
                child: _BookingRow(
                  booking: todays[i],
                  due: dueByBooking[todays[i].id],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _BookingRow extends StatefulWidget {
  const _BookingRow({required this.booking, this.due});
  final Booking booking;
  final double? due;

  @override
  State<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends State<_BookingRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isNight = b.shift == Shift.night;
    final accent = isNight ? WebTheme.night : WebTheme.amber;
    final price = b.customPrice;
    final client = (b.clientName?.isNotEmpty == true)
        ? b.clientName!
        : b.title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .pushNamed(RouteNames.bookingDetail, arguments: b.id),
        child: AnimatedContainer(
          duration: WebTheme.base,
          curve: WebTheme.ease,
          transform: Matrix4.translationValues(_hover ? 4 : 0, 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _hover ? WebTheme.orangeTint : WebTheme.pageBg,
            borderRadius: BorderRadius.circular(WebTheme.rRow),
            border: Border(
              left: BorderSide(color: accent, width: 3),
              top: BorderSide(
                  color: _hover ? WebTheme.orange : WebTheme.innerLine),
              right: BorderSide(
                  color: _hover ? WebTheme.orange : WebTheme.innerLine),
              bottom: BorderSide(
                  color: _hover ? WebTheme.orange : WebTheme.innerLine),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  children: [
                    Text('${b.date.day}',
                        style: WebTheme.displayStyle(
                            size: 21, weight: FontWeight.w800, height: 1)),
                    Text(
                        DateFormat('MMM').format(b.date).toUpperCase(),
                        style: WebTheme.label(
                            size: 8,
                            color: WebTheme.inkMuted,
                            tracking: 0.15)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                            size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(b.eventType.vibe.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                            size: 11.5, color: WebTheme.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _ShiftChip(night: isNight),
              const SizedBox(width: 16),
              Expanded(
                flex: 10,
                child: Text(
                  b.venue ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      WebTheme.bodyStyle(size: 12, color: WebTheme.inkSoft),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price == null ? '—' : _formatBdt((price * 100).round()),
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: WebTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (price != null)
                    Text(
                      (widget.due ?? 0) > 0.5
                          ? 'Due ${_formatBdt((widget.due! * 100).round())}'
                          : 'Paid ✓',
                      style: TextStyle(
                        fontFamily: WebTheme.mono,
                        fontSize: 10,
                        color: (widget.due ?? 0) > 0.5
                            ? WebTheme.danger
                            : WebTheme.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DAY (orange tint) / NIGHT (purple tint) chip, Space Mono 9 uppercase.
class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.night});
  final bool night;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: night ? WebTheme.nightTint : WebTheme.orangeTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color:
                night ? WebTheme.nightTintBorder : WebTheme.orangeTintBorder),
      ),
      child: Center(
        child: Text(
          night ? 'NIGHT' : 'DAY',
          style: WebTheme.label(
            size: 9,
            tracking: 0.1,
            color: night ? WebTheme.nightText : WebTheme.orangeDeep,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── QUICK ACTIONS
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final freelancer = role == UserRole.freelancer;
    final actions = freelancer
        ? const [
            (Icons.calendar_month_rounded, 'Calendar', RouteNames.calendar),
            (Icons.business_rounded, 'Company',
                RouteNames.freelancerCompanies),
            (Icons.sticky_note_2_outlined, 'Notes', RouteNames.notes),
            (Icons.shopping_bag_outlined, 'Expense',
                RouteNames.financeExpenses),
          ]
        : const [
            (Icons.calendar_month_rounded, 'Calendar', RouteNames.calendar),
            (Icons.receipt_long_rounded, 'Invoice', RouteNames.invoice),
            (Icons.sticky_note_2_outlined, 'Notes', RouteNames.notes),
            (Icons.groups_rounded, 'Team', RouteNames.team),
          ];

    const tints = [
      (WebTheme.orangeTint, WebTheme.orange),
      (WebTheme.amberTint, WebTheme.amberDeep),
      (WebTheme.successTint, WebTheme.success),
      (WebTheme.nightTint, WebTheme.nightText),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i != 0) const SizedBox(width: 14),
          Expanded(
            child: _ActionCard(
              icon: actions[i].$1,
              label: actions[i].$2,
              iconBg: tints[i].$1,
              iconColor: tints[i].$2,
              onTap: () =>
                  Navigator.of(context).pushNamed(actions[i].$3),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WebTheme.base,
          curve: WebTheme.ease,
          transform:
              Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(WebTheme.rTile),
            border: Border.all(
                color: _hover ? WebTheme.orange : WebTheme.hairline),
            boxShadow:
                _hover ? WebTheme.cardShadowHover : WebTheme.cardShadowSmall,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child:
                    Icon(widget.icon, size: 18, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTheme.bodyStyle(
                      size: 13, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════ RIGHT PANEL
class _RightPanel extends StatelessWidget {
  const _RightPanel({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? UserRole.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebEntrance(
          delay: const Duration(milliseconds: 120),
          child: _FinancePanel(role: role),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 180),
          child: const _AnnouncementPanel(),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 240),
          child: const _MiniCalendar(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── FINANCE PANEL
/// Role-aware finance summary (handoff): Owner/Both = Collection + Due tiles,
/// TOP DUES list, SEND REMINDERS. Manager = hidden-income notice + dues.
/// Freelancer = My Earnings + Request Payment.
class _FinancePanel extends ConsumerWidget {
  const _FinancePanel({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = DateFormat('MMMM').format(DateTime.now());

    if (role == UserRole.freelancer) {
      return _card(
        context,
        title: 'My Earnings · $month',
        children: [
          Text(
            'Request a payout for your completed events — approvals land on '
            'the 15th.',
            style: WebTheme.bodyStyle(size: 12, color: WebTheme.inkSoft),
          ),
          const SizedBox(height: 14),
          _OrangeButton(
            label: 'REQUEST PAYMENT',
            onTap: () => Navigator.of(context)
                .pushNamed(RouteNames.teamSalarySheet),
          ),
        ],
      );
    }

    final m = ref.watch(dashboardMetricsProvider).valueOrNull ??
        DashboardMetrics.placeholder;
    final dues =
        ref.watch(dueBreakdownProvider).valueOrNull ?? const <DueEntry>[];
    final topDues = [...dues]..sort((a, b) => b.due.compareTo(a.due));
    final shown = topDues.take(4).toList();

    final isManager = role == UserRole.manager;

    return _card(
      context,
      title: 'Finance · $month',
      children: [
        if (isManager)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebTheme.pageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebTheme.innerLine),
            ),
            child: Text(
              'Income & profit are hidden for the Manager role. Client dues '
              'remain visible below.',
              style: WebTheme.bodyStyle(size: 11.5, color: WebTheme.inkSoft),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _tile('COLLECTION · TODAY',
                    _formatBdt(m.todayCollection), WebTheme.orangeTint,
                    WebTheme.orangeTintBorder, WebTheme.orangeDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile('DUE', _formatBdt(m.pendingDue),
                    WebTheme.dangerTint, WebTheme.dangerTintBorder,
                    WebTheme.danger),
              ),
            ],
          ),
        const SizedBox(height: 14),
        Text('TOP DUES',
            style: WebTheme.label(
                size: 9, color: WebTheme.inkMuted, tracking: 0.2)),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Text('No outstanding dues 🎉',
              style: WebTheme.bodyStyle(
                  size: 12, color: WebTheme.inkMuted))
        else
          for (final d in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.clientName?.isNotEmpty == true
                          ? d.clientName!
                          : d.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(
                          size: 12.5, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatBdt((d.due * 100).round()),
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WebTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 6),
        _OrangeButton(
          label: 'SEND REMINDERS',
          onTap: () =>
              Navigator.of(context).pushNamed(RouteNames.reminders),
        ),
      ],
    );
  }

  Widget _tile(String label, String value, Color bg, Color border,
      Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WebTheme.label(
                  size: 8, color: WebTheme.inkMuted, tracking: 0.12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: WebTheme.displayStyle(
                    size: 17, weight: FontWeight.w800, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: WebTheme.displayStyle(size: 16)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Full-width orange pill button with mono uppercase label + glow.
class _OrangeButton extends StatefulWidget {
  const _OrangeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_OrangeButton> createState() => _OrangeButtonState();
}

class _OrangeButtonState extends State<_OrangeButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WebTheme.base,
          curve: WebTheme.ease,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? WebTheme.orangeDark : WebTheme.orange,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            boxShadow: WebTheme.buttonGlow,
          ),
          child: Center(
            child: Text(widget.label,
                style: WebTheme.label(
                    size: 9,
                    color: WebTheme.chromeInk,
                    tracking: 0.15,
                    weight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── ANNOUNCEMENT PANEL
/// Dark #2B1D12 card with the latest (pinned-first) announcement. Links to
/// the Announcements screen.
class _AnnouncementPanel extends ConsumerWidget {
  const _AnnouncementPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(sortedAnnouncementsProvider).valueOrNull ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final a = items.first;

    return WebHoverLift(
      onTap: () =>
          Navigator.of(context).pushNamed(RouteNames.announcements),
      borderRadius: WebTheme.rCard,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WebTheme.chrome,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          boxShadow: WebTheme.darkCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📌 ANNOUNCEMENT',
                style: WebTheme.label(
                    size: 9, color: WebTheme.amber, tracking: 0.2)),
            const SizedBox(height: 10),
            Text(a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WebTheme.bodyStyle(
                    size: 14,
                    weight: FontWeight.w700,
                    color: WebTheme.chromeInk)),
            const SizedBox(height: 6),
            Text(a.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: WebTheme.bodyStyle(
                    size: 12, color: WebTheme.chromeInkMuted)),
            const SizedBox(height: 12),
            Text('VIEW ALL →',
                style: WebTheme.label(
                    size: 9, color: WebTheme.amber, tracking: 0.12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── MINI CALENDAR
/// Month grid (Monday start): ‹ › month nav, MO–SU header (SA/SU orange),
/// today = orange square, gold/purple event dots, next-holiday footer.
class _MiniCalendar extends ConsumerStatefulWidget {
  const _MiniCalendar();

  @override
  ConsumerState<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends ConsumerState<_MiniCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // day → (hasDay, hasNight) for the visible month.
    final dots = <int, (bool, bool)>{};
    for (final b in bookings) {
      if (b.status == BookingStatus.cancelled) continue;
      if (b.date.year != _month.year || b.date.month != _month.month) {
        continue;
      }
      final prev = dots[b.date.day] ?? (false, false);
      dots[b.date.day] = b.shift == Shift.night
          ? (prev.$1, true)
          : (true, prev.$2);
    }

    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final leading = firstWeekday - 1; // Monday start
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;

    final holiday = _nextHoliday(today);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(DateFormat('MMMM yyyy').format(_month),
                  style: WebTheme.displayStyle(size: 15)),
              const Spacer(),
              _roundNav('‹', () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                  })),
              const SizedBox(width: 6),
              _roundNav('›', () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                  })),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'][i],
                      style: WebTheme.label(
                        size: 8.5,
                        tracking: 0.1,
                        color: i >= 5
                            ? WebTheme.orange
                            : WebTheme.inkMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var week = 0;
              week * 7 < leading + daysInMonth;
              week++) ...[
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _cell(week * 7 + i - leading + 1, daysInMonth,
                        today, dots),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
          if (holiday != null)
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: WebTheme.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next holiday: ${holiday.name} · '
                    '${DateFormat('d MMM').format(holiday.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 11, color: WebTheme.inkSoft),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, int daysInMonth, DateTime today,
      Map<int, (bool, bool)> dots) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 34);
    final isToday = today.year == _month.year &&
        today.month == _month.month &&
        today.day == day;
    final d = dots[day];

    return SizedBox(
      height: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 22,
            decoration: BoxDecoration(
              color: isToday ? WebTheme.orange : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$day',
                style: WebTheme.bodyStyle(
                  size: 11.5,
                  weight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? WebTheme.chromeInk : WebTheme.inkSoft,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (d?.$1 == true)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                        color: WebTheme.amber, shape: BoxShape.circle),
                  ),
                if (d?.$2 == true)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                        color: WebTheme.night, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundNav(String glyph, VoidCallback onTap) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: 999,
      builder: (context, hovering) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: hovering ? WebTheme.orange : WebTheme.hairline),
        ),
        child: Center(
          child: Text(glyph,
              style: TextStyle(
                fontSize: 13,
                color: hovering ? WebTheme.orange : WebTheme.inkMuted,
                height: 1,
              )),
        ),
      ),
    );
  }

  /// The next BD holiday on/after [from] (looks up to 2 months ahead).
  static BdHoliday? _nextHoliday(DateTime from) {
    for (var i = 0; i < 3; i++) {
      final month = DateTime(from.year, from.month + i);
      for (final h in bdHolidaysOfMonth(month)) {
        if (!h.date.isBefore(from)) return h;
      }
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════ SHARED PIECES
/// Space-Mono orange micro-link ("VIEW ALL →").
class _MonoLink extends StatelessWidget {
  const _MonoLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      builder: (context, hovering) => Text(
        label,
        style: WebTheme.label(
          size: 10,
          color: hovering ? WebTheme.orangeDark : WebTheme.orange,
          tracking: 0.1,
        ),
      ),
    );
  }
}

/// Hover → translate by [dy] px (the handoff's lift). Reduce-motion aware.
class _HoverTranslate extends StatefulWidget {
  const _HoverTranslate({
    required this.child,
    required this.dy,
    this.onTap,
  });

  final Widget child;
  final double dy;
  final VoidCallback? onTap;

  @override
  State<_HoverTranslate> createState() => _HoverTranslateState();
}

class _HoverTranslateState extends State<_HoverTranslate> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: noMotion ? Duration.zero : WebTheme.base,
          curve: WebTheme.ease,
          transform: Matrix4.translationValues(
              0, _hover && !noMotion ? widget.dy : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Scale 0.92 → 1 pop with the overshoot curve (handoff `popIn`).
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (noMotion) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.92, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: WebTheme.spring));
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: ScaleTransition(scale: scale, child: widget.child),
    );
  }
}

/// A bar that grows from the bottom (scaleY 0 → 1) with a stagger delay —
/// the handoff's `barGrow`. Reduce-motion renders the final bar instantly.
class _GrowBar extends StatefulWidget {
  const _GrowBar({
    required this.heightFraction,
    required this.maxHeight,
    required this.decoration,
    this.delay = Duration.zero,
  });

  final double heightFraction;
  final double maxHeight;
  final BoxDecoration decoration;
  final Duration delay;

  @override
  State<_GrowBar> createState() => _GrowBarState();
}

class _GrowBarState extends State<_GrowBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (noMotion) {
      _c.value = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t =
              CurvedAnimation(parent: _c, curve: WebTheme.ease).value;
          return Container(
            height: widget.maxHeight * widget.heightFraction * t,
            decoration: widget.decoration,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────── DASHBOARD NAV
/// Opens the booking list pre-filtered exactly like the mobile dashboard's
/// tappable cards, so a web card tap behaves identically (parity). Each
/// helper sets [bookingFilterProvider] then navigates to the Bookings route.
class DashboardNav {
  const DashboardNav._();

  static void _go(WidgetRef ref, BuildContext context, BookingFilter filter) {
    ref.read(bookingFilterProvider.notifier).state = filter;
    Navigator.of(context).pushNamed(RouteNames.bookings);
  }

  /// Today's events (today card / hero).
  static void openToday(WidgetRef ref, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _go(
      ref,
      context,
      ref.read(bookingFilterProvider).copyWith(
            from: today,
            to: today.add(const Duration(days: 1)),
            statuses: {},
          ),
    );
  }

  /// Upcoming = future, still-to-do events (no upper bound).
  static void openUpcoming(WidgetRef ref, BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _go(
      ref,
      context,
      ref.read(bookingFilterProvider).copyWith(
            from: tomorrow,
            clearTo: true,
            statuses: {
              BookingStatus.pending,
              BookingStatus.confirmed,
              BookingStatus.inProgress,
              BookingStatus.shotComplete,
            },
          ),
    );
  }

  /// Total = every booking, no date/status filter.
  static void openAll(WidgetRef ref, BuildContext context) {
    _go(
      ref,
      context,
      ref
          .read(bookingFilterProvider)
          .copyWith(clearFrom: true, clearTo: true, statuses: {}),
    );
  }

  /// Delivered = shot-complete + delivered + completed, any date.
  static void openDelivered(WidgetRef ref, BuildContext context) {
    _go(
      ref,
      context,
      ref.read(bookingFilterProvider).copyWith(
            statuses: {
              BookingStatus.shotComplete,
              BookingStatus.delivered,
              BookingStatus.completed,
            },
            clearFrom: true,
            clearTo: true,
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

/// `"16:30"` → `"4:30 PM"`.
String _time12(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return hhmm;
  final dt = DateTime(2000, 1, 1, h, m);
  return DateFormat('h:mm a').format(dt);
}
