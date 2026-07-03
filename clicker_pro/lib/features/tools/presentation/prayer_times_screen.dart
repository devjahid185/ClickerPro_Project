// lib/features/tools/presentation/prayer_times_screen.dart
//
// নামাজের সময় — today's five prayer times, computed fully offline from the
// device date + a location (Dhaka by default). Highlights the next prayer.

import 'package:flutter/material.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/prayer/prayer_times.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final times = const PrayerTimesCalculator().forDate(now);
    final next = times.nextAfter(now);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Prayer Times',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dhaka, Bangladesh · ${_dateLabel(now)}',
                    style: TextStyle(color: AppColors.film, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final e in times.schedule)
            _PrayerRow(
              name: e.name,
              time: e.time,
              isNext: next != null && next.name == e.name,
              isInformational: e.name == 'Sunrise',
            ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) =>
      BookingFormat.dateTime(d, lang: 'en');
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isInformational,
  });

  final String name;
  final DateTime time;
  final bool isNext;
  final bool isInformational;

  @override
  Widget build(BuildContext context) {
    final accent = isNext ? AppColors.orange : AppColors.filmDim;
    final label = BookingFormat.clockTime(
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.orange.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? AppColors.orange.withValues(alpha: 0.4)
              : AppColors.line(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isInformational
                ? Icons.wb_twilight_outlined
                : Icons.mosque_outlined,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isInformational ? AppColors.filmDim : AppColors.film,
                fontSize: 15,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isNext)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'NEXT',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: isNext ? AppColors.orange : AppColors.film,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
