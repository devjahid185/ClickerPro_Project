// lib/features/bookings/presentation/widgets/status_timeline.dart
//
// Vertical timeline of status transitions. Each row shows
// `from -> to`, the actor, a relative-or-absolute timestamp, and an
// optional truncated note. Pending rows render with an orange dot until
// the outbox worker reports a successful sync.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Components and Interfaces". Validates Requirements 3.9, 3.10,
// 9.1–9.6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking_status/booking_status.dart';
import '../../../../core/format/booking_format.dart';
import '../../../../features/settings/application/language_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/status_history_entry.dart';
import 'booking_status_badge.dart';
import 'detail_section.dart';

class StatusTimeline extends ConsumerWidget {
  const StatusTimeline({super.key, required this.entries});

  final List<StatusHistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    return DetailSection(
      title: 'Status History',
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No status changes yet.',
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entries.length; i++)
                  _TimelineRow(
                    entry: entries[i],
                    lang: lang,
                    isLast: i == entries.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.lang,
    required this.isLast,
  });

  final StatusHistoryEntry entry;
  final String lang;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = entry.pending
        ? AppColors.orange
        : statusDotColor(entry.toStatus);
    final timeText = BookingFormat.relative(entry.at, lang: lang);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator rail — dot + connector line.
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: entry.pending
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: -1,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: AppColors.line(0.08),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Row body.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusChip(status: entry.fromStatus, faded: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                        ),
                      ),
                      _StatusChip(status: entry.toStatus),
                      if (entry.pending) ...[
                        const SizedBox(width: 8),
                        Text(
                          'pending sync',
                          style: TextStyle(
                            color: AppColors.orange.withValues(alpha: 0.85),
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: AppColors.filmMuted.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                      decoration: BoxDecoration(
                        color: AppColors.line(0.025),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.line(0.05),
                        ),
                      ),
                      child: Text(
                        entry.note!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.film.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smaller status pill for the timeline-row inline use. Not the same as
/// `BookingStatusBadge` which is the canonical "current status" pill —
/// here we render two of them (from / to) at lower weight.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.faded = false});

  final BookingStatus status;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final color = statusDotColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: faded ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: faded ? 0.3 : 0.45)),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: faded ? color.withValues(alpha: 0.7) : color,
          fontSize: 9.5,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
