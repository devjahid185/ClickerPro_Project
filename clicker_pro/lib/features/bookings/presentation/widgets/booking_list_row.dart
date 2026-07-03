// lib/features/bookings/presentation/widgets/booking_list_row.dart
//
// Single row in the booking list. Renders title, optional client name,
// date+time, status badge, and a "pending sync" dot when the row has
// unsynced local changes. Uses Bengali numerals for the date when the
// active locale is `bn` via `BookingFormat.dateTime`.
//
// Visibility of the optional payment subtitle is gated by the screen
// (Property 3 predicate); this row simply renders whatever subtitle
// string the caller passes — null collapses the line.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Components and Interfaces" section. Validates Requirements 1.10,
// 1.11, 1.13, 5.3, 5.4, 11.3.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../features/settings/application/language_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/web_theme.dart';
import '../../domain/booking.dart';
import 'booking_status_badge.dart';

/// Card surface for a booking row. On web we use a crisp white card with a
/// soft warm shadow (so the dark title/body text is fully legible — the
/// "booking page unreadable" fix). On mobile we keep the existing glass look.
BoxDecoration _rowDecoration() {
  if (kIsWeb) {
    return BoxDecoration(
      color: WebTheme.surface,
      borderRadius: BorderRadius.circular(WebTheme.rCard),
      border: Border.all(color: WebTheme.hairline, width: 1),
      boxShadow: WebTheme.cardShadow,
    );
  }
  return AppColors.glassCardDecoration();
}

class BookingListRow extends ConsumerWidget {
  const BookingListRow({
    super.key,
    required this.booking,
    this.clientName,
    this.subtitle,
    this.onTap,
  });

  final Booking booking;

  /// Resolved client display name. The repository returns Booking rows
  /// without joined Client data, so the screen looks up the client and
  /// passes the name down. Null collapses the client line.
  final String? clientName;

  /// Optional secondary line — typically a payment summary or venue.
  /// Passed in by the screen so visibility gating happens once at the
  /// screen level rather than in every row.
  final String? subtitle;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    final dateLine = BookingFormat.dateTime(booking.date, lang: lang);
    final timeLine =
        BookingFormat.clockRange(booking.startTime, booking.endTime, lang: lang);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: _rowDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date column — calendar-style stacked day + month.
              _DateBlock(date: booking.date, lang: lang),
              const SizedBox(width: 14),
              // Title + client + subtitle.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.film,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (booking.pending) ...[
                          const SizedBox(width: 6),
                          const _PendingDot(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (clientName != null)
                      Text(
                        clientName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.filmDim.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BookingStatusBadge(booking.status),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$dateLine · $timeLine',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.filmMuted.withValues(alpha: 0.9),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.gold.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.filmMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendar-style date block: large day number + small month abbreviation.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.lang});

  final DateTime date;
  final String lang;

  @override
  Widget build(BuildContext context) {
    // intl handles locale-aware day-of-month and abbreviated-month
    // rendering for both en and bn (bn returns Bengali digits and
    // Bengali month names).
    final dayText = DateFormat('d', lang).format(date);
    final month = DateFormat('MMM', lang).format(date).toUpperCase();

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line(0.06),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayText,
            style: TextStyle(
              color: AppColors.film,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDot extends StatelessWidget {
  const _PendingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
    );
  }
}
