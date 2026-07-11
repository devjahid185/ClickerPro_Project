// lib/features/bookings/presentation/web_calendar.dart
//
// Graphy7 — WEB-ONLY calendar screen (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 3).
//
// One large white card: "Month Year" + ‹ › round nav + a MONTH/WEEK/DAY
// segmented control (active = orange pill). MON–SUN labels (SAT/SUN orange).
// Month view: 7-col grid of day cells (min-height 86, radius 14, cream bg,
// inner border; today = orange border + orange-tint bg + orange number) with
// ellipsized event chips — day events orange-tint, night events purple-tint.
// Cells pop in with a small per-cell stagger; hover = orange border + lift.
//
// WEEK shows the current 7-day row with the same chips; DAY lists that day's
// bookings. Clicking any event chip / row opens Event Details.
//
// Data comes from the same booking providers the mobile screens use.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type_vibe.dart';
import '../domain/shift.dart';

enum _View { month, week, day }

/// The wide-web calendar. Pure presentation over the existing providers.
class WebCalendar extends ConsumerStatefulWidget {
  const WebCalendar({super.key});

  @override
  ConsumerState<WebCalendar> createState() => _WebCalendarState();
}

class _WebCalendarState extends ConsumerState<WebCalendar> {
  _View _view = _View.month;
  late DateTime _anchor; // month for month view; day for week/day views

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, now.day);
  }

  void _step(int dir) {
    setState(() {
      _anchor = switch (_view) {
        _View.month => DateTime(_anchor.year, _anchor.month + dir, 1),
        _View.week => _anchor.add(Duration(days: 7 * dir)),
        _View.day => _anchor.add(Duration(days: dir)),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref
            .watch(bookingListProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];
    final active = bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .toList();

    final title = switch (_view) {
      _View.month => DateFormat('MMMM yyyy').format(_anchor),
      _View.week => 'Week of ${DateFormat('d MMM').format(_weekStart)}',
      _View.day => DateFormat('EEEE, d MMMM').format(_anchor),
    };

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          WebEntrance(
            delay: const Duration(milliseconds: 50),
            child: Container(
              padding: const EdgeInsets.all(26),
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
                      Text(title,
                          style: WebTheme.displayStyle(
                              size: 20, weight: FontWeight.w800)),
                      const SizedBox(width: 16),
                      _roundNav('‹', () => _step(-1)),
                      const SizedBox(width: 6),
                      _roundNav('›', () => _step(1)),
                      const Spacer(),
                      _Segmented(
                        view: _view,
                        onView: (v) => setState(() => _view = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  switch (_view) {
                    _View.month => _MonthGrid(
                        month: _anchor,
                        bookings: active,
                      ),
                    _View.week => _WeekRow(
                        weekStart: _weekStart,
                        bookings: active,
                      ),
                    _View.day => _DayList(
                        day: _anchor,
                        bookings: active,
                      ),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime get _weekStart =>
      _anchor.subtract(Duration(days: _anchor.weekday - 1));

  Widget _roundNav(String glyph, VoidCallback onTap) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: 999,
      builder: (context, hovering) => Container(
        width: 30,
        height: 30,
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
}

// ─────────────────────────────────────────────────── SEGMENTED CONTROL
class _Segmented extends StatelessWidget {
  const _Segmented({required this.view, required this.onView});
  final _View view;
  final ValueChanged<_View> onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WebTheme.pageBg,
        borderRadius: BorderRadius.circular(WebTheme.rFull),
        border: Border.all(color: WebTheme.innerLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in _View.values)
            WebHoverHighlight(
              onTap: () => onView(v),
              borderRadius: WebTheme.rFull,
              builder: (context, hovering) => AnimatedContainer(
                duration: WebTheme.base,
                curve: WebTheme.ease,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: v == view ? WebTheme.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(WebTheme.rFull),
                ),
                child: Text(
                  v.name.toUpperCase(),
                  style: WebTheme.label(
                    size: 10,
                    tracking: 0.08,
                    color: v == view
                        ? WebTheme.chromeInk
                        : hovering
                            ? WebTheme.ink
                            : WebTheme.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── WEEKDAY LABELS
class _DowLabels extends StatelessWidget {
  const _DowLabels();

  static const _labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i != 0) const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                _labels[i],
                style: WebTheme.label(
                  size: 9,
                  tracking: 0.14,
                  color: i >= 5 ? WebTheme.orange : WebTheme.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────────────────────────────────────── MONTH VIEW
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.bookings});
  final DateTime month;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - 1; // Monday start
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    final byDay = <int, List<Booking>>{};
    for (final b in bookings) {
      if (b.date.year != month.year || b.date.month != month.month) continue;
      (byDay[b.date.day] ??= []).add(b);
    }

    return Column(
      children: [
        const _DowLabels(),
        const SizedBox(height: 8),
        for (var row = 0; row * 7 < totalCells; row++) ...[
          if (row != 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < 7; col++) ...[
                if (col != 0) const SizedBox(width: 8),
                Expanded(
                  child: _cell(context, row * 7 + col, leading,
                      daysInMonth, byDay),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(BuildContext context, int index, int leading,
      int daysInMonth, Map<int, List<Booking>> byDay) {
    final day = index - leading + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 86);
    }
    final now = DateTime.now();
    final isToday =
        now.year == month.year && now.month == month.month && now.day == day;
    final events = byDay[day] ?? const <Booking>[];

    return _PopCell(
      delay: Duration(milliseconds: (12 * index).clamp(0, 500)),
      child: _HoverCell(
        onTap: events.length == 1
            ? () => Navigator.of(context).pushNamed(
                RouteNames.bookingDetail,
                arguments: events.first.id)
            : null,
        isToday: isToday,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: WebTheme.displayStyle(
                size: 13,
                weight: FontWeight.w700,
                color: isToday ? WebTheme.orange : WebTheme.ink,
              ),
            ),
            const SizedBox(height: 5),
            for (final e in events.take(3)) ...[
              _EventChip(booking: e),
              const SizedBox(height: 3),
            ],
            if (events.length > 3)
              Text('+${events.length - 3} more',
                  style: WebTheme.label(
                      size: 8, color: WebTheme.inkMuted, tracking: 0.05)),
          ],
        ),
      ),
    );
  }
}

/// Cream day cell with hover lift + orange border; today pre-highlighted.
class _HoverCell extends StatefulWidget {
  const _HoverCell({
    required this.child,
    required this.isToday,
    this.onTap,
  });

  final Widget child;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  State<_HoverCell> createState() => _HoverCellState();
}

class _HoverCellState extends State<_HoverCell> {
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
              0, _hover && !noMotion ? -2 : 0, 0),
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: widget.isToday ? WebTheme.orangeTint : WebTheme.pageBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover || widget.isToday
                  ? WebTheme.orange
                  : WebTheme.innerLine,
              width: widget.isToday ? 1.5 : 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tiny ellipsized event chip — orange tint for day, purple for night.
class _EventChip extends StatelessWidget {
  const _EventChip({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final night = booking.shift == Shift.night;
    final label = (booking.clientName?.trim().isNotEmpty ?? false)
        ? '${booking.eventType.vibe.label}—${booking.clientName!.trim()}'
        : booking.title;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(RouteNames.bookingDetail, arguments: booking.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: night ? WebTheme.nightTint : WebTheme.orangeTint,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WebTheme.bodyStyle(
              size: 9.5,
              weight: FontWeight.w600,
              color: night ? WebTheme.nightText : WebTheme.orangeDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// popIn (scale 0.92 → 1) with stagger — reduce-motion renders instantly.
class _PopCell extends StatefulWidget {
  const _PopCell({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_PopCell> createState() => _PopCellState();
}

class _PopCellState extends State<_PopCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
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
    final curved = CurvedAnimation(parent: _c, curve: WebTheme.ease);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
        child: widget.child,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── WEEK VIEW
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.weekStart, required this.bookings});
  final DateTime weekStart;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        const _DowLabels(),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i != 0) const SizedBox(width: 8),
              Expanded(
                child: Builder(builder: (context) {
                  final day = weekStart.add(Duration(days: i));
                  final events = bookings
                      .where((b) =>
                          b.date.year == day.year &&
                          b.date.month == day.month &&
                          b.date.day == day.day)
                      .toList();
                  return _PopCell(
                    delay: Duration(milliseconds: 30 * i),
                    child: _HoverCell(
                      isToday: day == today,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${day.day}',
                              style: WebTheme.displayStyle(
                                size: 13,
                                weight: FontWeight.w700,
                                color: day == today
                                    ? WebTheme.orange
                                    : WebTheme.ink,
                              )),
                          const SizedBox(height: 5),
                          for (final e in events) ...[
                            _EventChip(booking: e),
                            const SizedBox(height: 3),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── DAY VIEW
class _DayList extends StatelessWidget {
  const _DayList({required this.day, required this.bookings});
  final DateTime day;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final events = bookings
        .where((b) =>
            b.date.year == day.year &&
            b.date.month == day.month &&
            b.date.day == day.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No events this day.',
              style:
                  WebTheme.bodyStyle(size: 13, color: WebTheme.inkMuted)),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          if (i != 0) const SizedBox(height: 8),
          WebEntrance(
            delay: Duration(milliseconds: 50 * i),
            offset: 6,
            child: _DayRow(booking: events[i]),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final night = booking.shift == Shift.night;
    final accent = night ? WebTheme.night : WebTheme.amber;
    final client = (booking.clientName?.trim().isNotEmpty ?? false)
        ? booking.clientName!.trim()
        : booking.title;

    return WebHoverHighlight(
      onTap: () => Navigator.of(context)
          .pushNamed(RouteNames.bookingDetail, arguments: booking.id),
      borderRadius: 12,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hovering
              ? (night ? WebTheme.nightTint : WebTheme.orangeTint)
              : WebTheme.pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accent, width: 3),
            top: const BorderSide(color: WebTheme.innerLine),
            right: const BorderSide(color: WebTheme.innerLine),
            bottom: const BorderSide(color: WebTheme.innerLine),
          ),
        ),
        child: Row(
          children: [
            Text(night ? '☾' : '☀', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client,
                      style: WebTheme.bodyStyle(
                          size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.eventType.vibe.label}'
                    '${booking.venue?.isNotEmpty == true ? ' · ${booking.venue}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 11.5, color: WebTheme.inkMuted),
                  ),
                ],
              ),
            ),
            Text(
              booking.startTime,
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 11,
                color: WebTheme.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
