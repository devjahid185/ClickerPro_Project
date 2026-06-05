// lib/widgets/info_row.dart
//
// Pixel-exact match to Dashboard.html v6.2 demo:
//   - Each card: 12 vertical, 14 horizontal padding, 14px radius
//   - Card layout: Row (emoji icon + body)
//   - Icon: 22px font (emoji)
//   - Number: serif 22px, weight 600 (red for cancel)
//   - Label: mono 9px, uppercase, letter-spacing 0.1em, film-muted

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final int holidayCount;
  final int cancelledCount;
  final VoidCallback? onHolidaysTap;
  final VoidCallback? onCancelledTap;

  const InfoRow({
    super.key,
    this.holidayCount = 2,
    this.cancelledCount = 7,
    this.onHolidaysTap,
    this.onCancelledTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            emoji: "🎉",
            number: holidayCount.toString(),
            label: "Holidays This Month",
            isCancel: false,
            onTap: onHolidaysTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            emoji: "❌",
            number: cancelledCount.toString(),
            label: "Cancelled Events",
            isCancel: true,
            onTap: onCancelledTap,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String number;
  final String label;
  final bool isCancel;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.emoji,
    required this.number,
    required this.label,
    required this.isCancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Emoji icon
              Text(emoji, style: const TextStyle(fontSize: 22, height: 1.0)),
              const SizedBox(width: 10),
              // Body
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: isCancel ? AppColors.red : AppColors.film,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.filmMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.9, // 0.1em on 9px
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
