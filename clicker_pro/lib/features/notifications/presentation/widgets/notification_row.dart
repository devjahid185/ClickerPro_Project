// lib/features/notifications/presentation/widgets/notification_row.dart
//
// Single row in the inbox.  Layout: category badge (icon + colour),
// message + relative time, optional "unread" dot on the right।  Tapping
// fires `onTap` which the screen wires to mark-as-read + deeplink।

import 'package:flutter/material.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/app_notification.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.lang,
    required this.onTap,
  });

  final AppNotification notification;
  final String lang;
  final VoidCallback onTap;

  ({IconData icon, Color colour, String label}) _categoryStyle(
    AppLocalizations loc,
  ) {
    switch (notification.category.toUpperCase()) {
      case 'OPERATIONS':
        return (
          icon: Icons.assignment_outlined,
          colour: AppColors.indigo,
          label: loc.notifications_category_operations,
        );
      case 'PAYMENT':
        return (
          icon: Icons.payments_outlined,
          colour: AppColors.green,
          label: loc.notifications_category_payment,
        );
      case 'REEDIT':
        return (
          icon: Icons.edit_note_outlined,
          colour: AppColors.orange,
          label: loc.notifications_category_reedit,
        );
      case 'ANNOUNCEMENT':
        return (
          icon: Icons.campaign_outlined,
          colour: AppColors.gold,
          label: loc.notifications_category_announcement,
        );
      case 'WISH':
        return (
          icon: Icons.cake_outlined,
          colour: AppColors.purple,
          label: loc.notifications_category_wish,
        );
      default:
        return (
          icon: Icons.notifications_outlined,
          colour: AppColors.filmDim,
          label: loc.notifications_category_other,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final style = _categoryStyle(loc);
    final unread = !notification.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? AppColors.glassHover : AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread
                  ? style.colour.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon badge
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: style.colour.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(style.icon, color: style.colour, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: TextStyle(
                        color: style.colour,
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BookingFormat.relative(notification.sentAt, lang: lang),
                      style: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
