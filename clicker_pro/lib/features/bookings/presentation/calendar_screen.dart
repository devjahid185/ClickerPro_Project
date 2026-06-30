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

import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../theme/app_colors.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import 'widgets/booking_status_badge.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(calendarMonthProvider);
    final bookingsAsync = ref.watch(calendarBookingsProvider(cursor));
    final policy = ref.watch(bookingsPolicyProvider);
    final loc = AppLocalizations.of(context);

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
        title: Text(
          loc.bookings_calendar,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bookings list',
            icon: Icon(Icons.event_note_outlined, color: AppColors.gold),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.bookings),
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
          child: Column(
            children: [
              const OfflineBanner(),
              _MonthHeader(
                cursor: cursor,
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.cursor,
    required this.onPrev,
    required this.onNext,
    required this.prevTooltip,
    required this.nextTooltip,
  });

  final ({int year, int month}) cursor;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String prevTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMM().format(
      DateTime(cursor.year, cursor.month, 1),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: prevTooltip,
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.gold),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: nextTooltip,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gold,
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
    // Sunday-first to match the rendered grid.
    const labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.85),
                  fontFamily: 'Montserrat',
                  fontSize: 10.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isToday
                ? AppColors.orange.withValues(alpha: 0.10)
                : AppColors.line(0.02),
            border: Border.all(
              color: isToday
                  ? AppColors.orange.withValues(alpha: 0.45)
                  : AppColors.line(0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isToday ? AppColors.orange : AppColors.film,
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (visible.isNotEmpty)
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final b in visible)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusDotColor(b.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
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
              fontFamily: 'Poppins',
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
                              '${b.startTime} – ${b.endTime}',
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
