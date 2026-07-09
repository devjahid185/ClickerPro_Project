// lib/features/bookings/presentation/calendar_screen.dart
//
// Monthly calendar view for the bookings module. Renders a 7-column,
// 6-row grid for the visible month with up to three status-coloured
// dots per day cell + a `+N` overflow indicator. Tapping a day opens
// a bottom sheet with the day's bookings; tapping a booking row
// navigates to the detail screen.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Calendar Screen". Validates Requirements 4.1–4.10.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/event_type_vibe.dart';
import '../domain/shift.dart';
import 'web_calendar.dart';
import 'widgets/booking_status_badge.dart';

/// Which calendar layout is active — wired to the Month/Week/Day toggle.
enum _CalView { month, week, day }

final _calViewProvider = StateProvider<_CalView>((ref) => _CalView.month);

/// The focused date for the Week and Day views (strip selection + agenda).
final _calDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(_calViewProvider);
    final cursor = ref.watch(calendarMonthProvider);
    final bookingsAsync = ref.watch(calendarBookingsProvider(cursor));
    final policy = ref.watch(bookingsPolicyProvider);
    final loc = AppLocalizations.of(context);

    // On wide web the WebNavShell owns the chrome; render the dedicated desktop
    // calendar instead of the mobile body. Mobile + narrow web are unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: WebCalendar(),
      );
    }

    return Scaffold(
      // WEB: transparent so the WebShell's light backdrop shows through and the
      // dark `film` text/cells stay legible. Mobile keeps its cream surface.
      backgroundColor: kIsWeb ? Colors.transparent : AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          loc.bookings_calendar,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 20,
          ),
        ),
        actions: [
          // .dc.html Calendar's Month/Week/Day segmented toggle — fully wired:
          // Month keeps the grid, Week shows a 7-day strip + agenda, Day shows
          // a single-day agenda.
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: _CalendarViewToggle(),
          ),
        ],
      ),
      floatingActionButton: policy.can(Capability.createBooking)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                loc.bookings_new_booking,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.bookingNew),
            )
          : null,
      body: SafeArea(
        // WEB: cap the calendar to a comfortable max width and centre it.
        // Without this, the wide content panel stretched each day cell to a
        // huge ~165px tall block (the "oversize" bug). Mobile keeps full width.
        child: _CalendarWidthLimit(
          child: switch (view) {
            _CalView.week => const _WeekView(),
            _CalView.day => const _DayView(),
            _CalView.month => Column(
              children: [
                const OfflineBanner(),
                _NavHeader(
                  label: DateFormat.yMMMM().format(
                    DateTime(cursor.year, cursor.month, 1),
                  ),
                  prevTooltip: loc.bookings_prev_month,
                  nextTooltip: loc.bookings_next_month,
                  onPrev: () => _shift(ref, cursor, -1),
                  onNext: () => _shift(ref, cursor, 1),
                ),
                const _WeekdayHeader(),
                Expanded(
                  child: bookingsAsync.when(
                    loading: () => const Center(child: LensLoader()),
                    error: (err, _) => Center(
                      child: ErrorState(
                        message: loc.bookings_calendar_could_not_load,
                        onRetry: () =>
                            ref.invalidate(calendarBookingsProvider(cursor)),
                      ),
                    ),
                    data: (bookings) => _MonthGrid(
                      cursor: cursor,
                      bookings: bookings,
                      onDayTap: (day) => _showDaySheet(context, day, bookings),
                    ),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  void _shift(WidgetRef ref, ({int year, int month}) cursor, int delta) {
    final next = DateTime(cursor.year, cursor.month + delta, 1);
    ref.read(calendarMonthProvider.notifier).state = (
      year: next.year,
      month: next.month,
    );
  }

  Future<void> _showDaySheet(
    BuildContext context,
    DateTime day,
    List<Booking> monthBookings,
  ) {
    final dayBookings =
        monthBookings
            .where((b) => _sameYmd(b.date, day))
            .toList(growable: false)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _DayBottomSheet(day: day, bookings: dayBookings),
    );
  }
}

bool _sameYmd(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// WEB-only width cap for the calendar. On web the content panel can be very
/// wide; an unconstrained 7-column grid then makes each day cell enormous.
/// This centres the calendar inside a sensible max width. On mobile it is a
/// pure pass-through, so the phone layout is unchanged.
class _CalendarWidthLimit extends StatelessWidget {
  const _CalendarWidthLimit({required this.child});
  final Widget child;

  static const double _maxWidth = 760;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: child,
      ),
    );
  }
}

/// Month/Week/Day segmented toggle from the .dc.html Calendar. Track is
/// surfaceAlt; the active segment is a solid-orange pill with white text.
class _CalendarViewToggle extends ConsumerWidget {
  const _CalendarViewToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_calViewProvider);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(ref, 'Month', _CalView.month, current),
          _seg(ref, 'Week', _CalView.week, current),
          _seg(ref, 'Day', _CalView.day, current),
        ],
      ),
    );
  }

  Widget _seg(WidgetRef ref, String label, _CalView value, _CalView current) {
    final active = value == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active
          ? null
          : () => ref.read(_calViewProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: active
            ? BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(7),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : AppColors.filmDim,
          ),
        ),
      ),
    );
  }
}

/// Shared `<  label  >` navigation header used by all three views (month
/// name, week range, or day). Matches the .dc.html month strip: muted
/// chevrons, centred w800 label.
class _NavHeader extends StatelessWidget {
  const _NavHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.prevTooltip,
    required this.nextTooltip,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String prevTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: prevTooltip,
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.filmDim),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.02 * 16,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: nextTooltip,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.filmDim,
            ),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    // Sunday-first single letters to match the .dc.html Calendar (MOD-12):
    // mono 9px muted, centred. (Two "T"s / two "S"s is intentional per design.)
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cursor,
    required this.bookings,
    required this.onDayTap,
  });

  final ({int year, int month}) cursor;
  final List<Booking> bookings;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(cursor.year, cursor.month, 1);
    // Sunday-first column index for the 1st (DateTime weekday: Mon=1..Sun=7).
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    // 6 rows × 7 cols = 42 cells (covers any month layout).
    const cellCount = 42;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          // Web cells read better slightly wider-than-tall; mobile keeps the
          // taller ratio so dots + day number fit on a narrow screen.
          childAspectRatio: kIsWeb ? 1.0 : 0.85,
        ),
        itemCount: cellCount,
        itemBuilder: (_, idx) {
          final dayOfMonth = idx - firstWeekday + 1;
          if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
            return const _BlankCell();
          }
          final date = DateTime(cursor.year, cursor.month, dayOfMonth);
          final dayBookings = bookings
              .where((b) => _sameYmd(b.date, date))
              .toList(growable: false);
          return _DayCell(
            date: date,
            bookings: dayBookings,
            onTap: dayBookings.isEmpty ? null : () => onDayTap(date),
          );
        },
      ),
    );
  }
}

class _BlankCell extends StatelessWidget {
  const _BlankCell();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.bookings,
    required this.onTap,
  });

  final DateTime date;
  final List<Booking> bookings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameYmd(date, DateTime.now());
    final visible = bookings.take(3).toList(growable: false);
    final overflow = bookings.length - visible.length;

    // .dc.html Calendar (MOD-12): cells are borderless; only *today* is a solid
    // orange rounded tile (radius 12, white w800, raised orange shadow). Day
    // number is centred with 4px status dots underneath.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: isToday
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: -6,
                      offset: const Offset(0, 8),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isToday ? Colors.white : AppColors.film,
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (visible.isNotEmpty) ...[
                const SizedBox(height: 3),
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final b in visible)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          // On the orange "today" tile, dots go white so they
                          // stay visible; otherwise use the status colour.
                          color: isToday
                              ? Colors.white
                              : statusDotColor(b.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.filmMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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

// ─── Week / Day views ───────────────────────────────────────────────────
//
// The Week view shows a Sunday-first 7-day strip (styled like the dashboard
// weekday strip in the .dc.html: mono label, white rounded tile, selected =
// solid orange) with the selected day's agenda underneath. The Day view is
// the same agenda navigated one day at a time. Both reuse the month-keyed
// bookings stream; a week spanning two months merges both streams.

/// Accent colour for a booking's shift — gold day / violet night / orange
/// full-day, matching the .dc.html agenda rows.
Color _shiftAccent(Shift shift) => switch (shift) {
  Shift.day => AppColors.gold,
  Shift.night => AppColors.purple,
  Shift.both => AppColors.orange,
};

/// Month keys covered by [start]..[end] — at most two for a week.
Set<({int year, int month})> _monthKeys(DateTime start, DateTime end) => {
  (year: start.year, month: start.month),
  (year: end.year, month: end.month),
};

class _WeekView extends ConsumerWidget {
  const _WeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selected = ref.watch(_calDayProvider);
    // Sunday-first week containing the selected day.
    final weekStart = selected.subtract(Duration(days: selected.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final days = [
      for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i)),
    ];

    final keys = _monthKeys(weekStart, weekEnd);
    final asyncs = [
      for (final key in keys) ref.watch(calendarBookingsProvider(key)),
    ];

    final Widget body;
    if (asyncs.any((a) => a.hasError)) {
      body = Center(
        child: ErrorState(
          message: loc.bookings_calendar_could_not_load,
          onRetry: () {
            for (final key in keys) {
              ref.invalidate(calendarBookingsProvider(key));
            }
          },
        ),
      );
    } else if (asyncs.any((a) => a.isLoading && !a.hasValue)) {
      body = const Center(child: LensLoader());
    } else {
      final bookings = [
        for (final a in asyncs) ...(a.value ?? const <Booking>[]),
      ];
      final dayBookings =
          bookings.where((b) => _sameYmd(b.date, selected)).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _WeekDayTile(
                      date: days[i],
                      selected: _sameYmd(days[i], selected),
                      bookings: bookings
                          .where((b) => _sameYmd(b.date, days[i]))
                          .toList(growable: false),
                      onTap: () =>
                          ref.read(_calDayProvider.notifier).state = DateTime(
                            days[i].year,
                            days[i].month,
                            days[i].day,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _DayAgendaList(day: selected, bookings: dayBookings)),
        ],
      );
    }

    // Week range label: "Jul 6 – 12" (same month) or "Jun 29 – Jul 5".
    final label = weekStart.month == weekEnd.month
        ? '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('d').format(weekEnd)}'
        : '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}';

    return Column(
      children: [
        const OfflineBanner(),
        _NavHeader(
          label: label,
          prevTooltip: 'Previous week',
          nextTooltip: 'Next week',
          onPrev: () => ref.read(_calDayProvider.notifier).state = selected
              .subtract(const Duration(days: 7)),
          onNext: () => ref.read(_calDayProvider.notifier).state = selected.add(
            const Duration(days: 7),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _DayView extends ConsumerWidget {
  const _DayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selected = ref.watch(_calDayProvider);
    final key = (year: selected.year, month: selected.month);
    final bookingsAsync = ref.watch(calendarBookingsProvider(key));

    return Column(
      children: [
        const OfflineBanner(),
        _NavHeader(
          label: DateFormat('EEE, MMM d').format(selected),
          prevTooltip: 'Previous day',
          nextTooltip: 'Next day',
          onPrev: () => ref.read(_calDayProvider.notifier).state = selected
              .subtract(const Duration(days: 1)),
          onNext: () => ref.read(_calDayProvider.notifier).state = selected.add(
            const Duration(days: 1),
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => const Center(child: LensLoader()),
            error: (err, _) => Center(
              child: ErrorState(
                message: loc.bookings_calendar_could_not_load,
                onRetry: () => ref.invalidate(calendarBookingsProvider(key)),
              ),
            ),
            data: (bookings) {
              final dayBookings =
                  bookings.where((b) => _sameYmd(b.date, selected)).toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));
              return _DayAgendaList(day: selected, bookings: dayBookings);
            },
          ),
        ),
      ],
    );
  }
}

/// One tile in the Week view's 7-day strip: mono weekday label, rounded day
/// tile (white hairline card; selected = solid orange with the raised
/// shadow), and a 5px status dot under days that have bookings.
class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    required this.date,
    required this.selected,
    required this.bookings,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final List<Booking> bookings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameYmd(date, DateTime.now());
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            DateFormat('EEE').format(date).toUpperCase(),
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.orange : AppColors.filmMuted,
            ),
          ),
          const SizedBox(height: 7),
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: selected
                    ? null
                    : Border.all(color: AppColors.line(0.05)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.55),
                          blurRadius: 16,
                          spreadRadius: -6,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (isToday ? AppColors.orange : AppColors.film),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bookings.isEmpty
                  ? Colors.transparent
                  : statusDotColor(bookings.first.status),
            ),
          ),
        ],
      ),
    );
  }
}

/// The agenda under the Week strip / Day header: "Thu, Jul 2 · 2 events"
/// caption + the .dc.html agenda rows, or a muted empty message.
class _DayAgendaList extends StatelessWidget {
  const _DayAgendaList({required this.day, required this.bookings});

  final DateTime day;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final caption = Row(
      children: [
        Text(
          DateFormat('EEE, MMM d').format(day),
          style: TextStyle(
            color: AppColors.film,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '· ${bookings.length} ${bookings.length == 1 ? 'event' : 'events'}',
          style: TextStyle(
            fontFamily: AppText.monoFontFamily,
            color: AppColors.filmMuted,
            fontSize: 10,
          ),
        ),
      ],
    );

    if (bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            caption,
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No events this day',
                style: TextStyle(color: AppColors.filmMuted, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 11), child: caption),
        for (final b in bookings) _AgendaRow(booking: b),
      ],
    );
  }
}

/// One agenda row per the .dc.html Calendar: white card radius 12, hairline
/// border with a 3px shift-coloured left rule, mono time, client/title and a
/// "Wedding · Venue" meta line. Tapping opens the booking detail.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final accent = _shiftAccent(booking.shift);
    final time = BookingFormat.clockRange(
      booking.startTime,
      booking.endTime,
      separator: '–',
    );
    final name = (booking.clientName?.trim().isNotEmpty ?? false)
        ? booking.clientName!
        : booking.title;
    final venue = booking.venue?.trim();
    final meta = (venue?.isNotEmpty ?? false)
        ? '${booking.eventType.vibe.label} · $venue'
        : booking.eventType.vibe.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: AppColors.line(0.06)),
          bottom: BorderSide(color: AppColors.line(0.06)),
          right: BorderSide(color: AppColors.line(0.06)),
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.bookingDetail, arguments: booking.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    time,
                    style: TextStyle(
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.trim().isEmpty ? 'Untitled' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.filmMuted,
                          fontSize: 11,
                        ),
                      ),
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

class _DayBottomSheet extends StatelessWidget {
  const _DayBottomSheet({required this.day, required this.bookings});

  final DateTime day;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMMEEEEd().format(day),
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final b in bookings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamed(RouteNames.bookingDetail, arguments: b.id);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: AppColors.glassCardDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.film,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              BookingFormat.clockRange(b.startTime, b.endTime),
                              style: TextStyle(
                                color: AppColors.filmDim.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      BookingStatusBadge(b.status),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.filmMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
