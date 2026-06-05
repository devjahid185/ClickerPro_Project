// lib/widgets/weekday_strip.dart
//
// Slim weekday strip:
//   - Wrapper: gradient card, 6px vertical / 8px horizontal padding, 14px radius
//   - 5 day cells: grid gap 4px
//   - DOW label: mono 9px, letter-spacing 0.85, film-muted color
//   - Day number: serif 16px, weight 600
//   - Today: filled orange gradient background + white bold text + soft glow
//   - Has-event dot: 4px orange dot below number (white on today)

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WeekdayStrip extends StatelessWidget {
  final Set<int>? eventDays;
  final void Function(DateTime)? onDayTap;

  const WeekdayStrip({super.key, this.eventDays, this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(5, (i) => monday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Row(
        children: List.generate(days.length, (i) {
          final d = days[i];
          final isToday = _isSameDay(d, now);
          final hasEvent = eventDays?.contains(d.day) ?? false;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 2,
                right: i == days.length - 1 ? 0 : 2,
              ),
              child: _DayCell(
                date: d,
                isToday: isToday,
                hasEvent: hasEvent,
                onTap: () => onDayTap?.call(d),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool hasEvent;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.hasEvent,
    required this.onTap,
  });

  String get _dayLabel {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final Color dowColor = isToday ? Colors.white : AppColors.filmMuted;
    final Color numColor = isToday ? Colors.white : AppColors.film;
    final Color dotColor = isToday
        ? Colors.white
        : (hasEvent ? AppColors.orange : Colors.transparent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        decoration: BoxDecoration(
          // Today: filled solid orange + soft glow
          color: isToday ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dayLabel,
              style: TextStyle(
                fontFamily: 'monospace',
                color: dowColor,
                fontSize: 9,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.85,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: numColor,
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            // Reserve a fixed slot so all cells line up; render dot only when needed.
            SizedBox(
              height: 4,
              child: dotColor == Colors.transparent
                  ? null
                  : Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
