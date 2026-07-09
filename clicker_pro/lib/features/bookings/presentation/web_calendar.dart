// lib/features/bookings/presentation/web_calendar.dart
//
// Graphy7 — WEB-ONLY calendar (Graphy7 Design).
//
// A desktop month grid, rendered ONLY on wide web. The mobile calendar body is
// 100% untouched (CalendarScreen routes here only when kIsWeb && width >= 900).
// Ported from the design source's "Calendar" screen: a header with month
// navigation, a legend, weekday labels, and a 6×7 grid whose cells carry the
// Gregorian day + Bengali numeral, a holiday tint, and per-booking event chips
// coloured by event-type vibe.
//
// All data comes from the same providers the mobile calendar uses
// (`calendarMonthProvider`, `calendarBookingsProvider`) — no new business
// logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/event_type_vibe.dart';

/// The wide-web calendar. Pure presentation over the existing providers.
class WebCalendar extends ConsumerWidget {
  const WebCalendar({super.key});

  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(calendarMonthProvider);
    final async = ref.watch(calendarBookingsProvider(cursor));
    final month = DateTime(cursor.year, cursor.month, 1);
    final bookings = async.value ?? const <Booking>[];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(
              child: _Header(
                month: month,
                sessions: bookings.length,
                onPrev: () => _shift(ref, cursor, -1),
                onNext: () => _shift(ref, cursor, 1),
                onNew: () =>
                    Navigator.of(context).pushNamed(RouteNames.bookingNew),
              ),
            ),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: _CalendarCard(month: month, bookings: bookings),
            ),
          ],
        ),
      ),
    );
  }

  void _shift(WidgetRef ref, ({int year, int month}) cur, int delta) {
    final d = DateTime(cur.year, cur.month + delta, 1);
    ref.read(calendarMonthProvider.notifier).state =
        (year: d.year, month: d.month);
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.sessions,
    required this.onPrev,
    required this.onNext,
    required this.onNew,
  });

  final DateTime month;
  final int sessions;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: WebTheme.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sessions == 1
                    ? '1 session scheduled this month'
                    : '$sessions sessions scheduled this month',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: WebTheme.sp4),
        _MonthNav(
          label: DateFormat.yMMMM().format(month),
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rButton),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: WebTheme.ink,
              ),
            ),
          ),
          _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      borderRadius: WebTheme.rChip,
      onTap: onTap,
      builder: (context, hovering) {
        return AnimatedContainer(
          duration: WebTheme.fast,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: hovering ? WebTheme.sageTint : Colors.transparent,
            borderRadius: BorderRadius.circular(WebTheme.rChip),
          ),
          child: Icon(icon, size: 19, color: WebTheme.inkSoft),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────── CALENDAR CARD
class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.month, required this.bookings});
  final DateTime month;
  final List<Booking> bookings;

  static const _dow = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    // Bookings indexed by day-of-month for this cursor month.
    final byDay = <int, List<Booking>>{};
    for (final b in bookings) {
      if (b.date.year == month.year && b.date.month == month.month) {
        byDay.putIfAbsent(b.date.day, () => []).add(b);
      }
    }
    final holidays = {
      for (final h in bdHolidaysOfMonth(month))
        if (!h.name.startsWith('Weekly Holiday')) h.date.day: h.name,
    };

    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Leading blanks so day 1 lands on its weekday column (Sun=0 … Sat=6).
    final lead = first.weekday % 7;
    final cells = <_Cell>[];
    for (var i = 0; i < lead; i++) {
      cells.add(const _Cell.blank());
    }
    final now = DateTime.now();
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      cells.add(_Cell(
        day: d,
        isToday: date.year == now.year &&
            date.month == now.month &&
            date.day == now.day,
        holiday: holidays[d],
        events: byDay[d] ?? const [],
        isFriday: date.weekday == DateTime.friday,
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(const _Cell.blank());
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Legend(),
          const SizedBox(height: WebTheme.sp4),
          Row(
            children: [
              for (final d in _dow)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                      color: WebTheme.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [for (final c in cells) _DayCell(cell: c)],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendDot(color: WebTheme.orange, label: 'Shoot'),
        SizedBox(width: 18),
        _LegendDot(color: WebTheme.rose, label: 'Holiday', tint: true),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.tint = false});
  final Color color;
  final String label;
  final bool tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: tint ? color.withValues(alpha: 0.22) : color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: WebTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// One grid position — either a blank spacer or a real day.
class _Cell {
  const _Cell({
    required this.day,
    required this.isToday,
    required this.holiday,
    required this.events,
    required this.isFriday,
  }) : blank = false;

  const _Cell.blank()
      : day = 0,
        isToday = false,
        holiday = null,
        events = const [],
        isFriday = false,
        blank = true;

  final int day;
  final bool isToday;
  final String? holiday;
  final List<Booking> events;
  final bool isFriday;
  final bool blank;
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.cell});
  final _Cell cell;

  /// Gregorian digits → Bengali numerals (matches the design source's দিন).
  static String _bn(int n) => n
      .toString()
      .split('')
      .map((d) => '০১২৩৪৫৬৭৮৯'[int.parse(d)])
      .join();

  @override
  Widget build(BuildContext context) {
    if (cell.blank) {
      return const SizedBox.shrink();
    }
    final isHoliday = cell.holiday != null;
    final Color bg = cell.isToday
        ? WebTheme.orangeSoft
        : isHoliday
            ? WebTheme.roseSoft
            : cell.isFriday
                ? WebTheme.sageTintSoft
                : WebTheme.surface;
    final Color border = cell.isToday
        ? WebTheme.orange
        : isHoliday
            ? WebTheme.rose.withValues(alpha: 0.35)
            : WebTheme.hairline;
    final Color numColor = cell.isToday
        ? WebTheme.orange
        : isHoliday
            ? WebTheme.rose
            : WebTheme.inkSoft;

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WebTheme.rChip),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cell.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: cell.isToday ? FontWeight.w800 : FontWeight.w600,
                  color: numColor,
                ),
              ),
              const Spacer(),
              Text(
                _bn(cell.day),
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 9,
                  color: WebTheme.inkFaint,
                ),
              ),
            ],
          ),
          if (isHoliday) ...[
            const SizedBox(height: 2),
            Text(
              cell.holiday!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: WebTheme.rose,
              ),
            ),
          ],
          for (final b in cell.events.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _EventChip(booking: b),
            ),
          if (cell.events.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '+${cell.events.length - 2} more',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.inkMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final vibe = booking.eventType.vibe;
    return WebHoverHighlight(
      borderRadius: 5,
      onTap: () => Navigator.of(context)
          .pushNamed(RouteNames.bookingDetail, arguments: booking.id),
      builder: (context, hovering) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: hovering ? vibe.color.withValues(alpha: 0.85) : vibe.color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            vibe.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
