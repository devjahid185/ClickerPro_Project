// lib/features/rent/presentation/widgets/rent_row.dart

import 'package:flutter/material.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/rent_record.dart';
import '../../../../theme/app_theme.dart';

class RentRow extends StatelessWidget {
  const RentRow({
    super.key,
    required this.record,
    required this.lang,
    required this.onMarkReturned,
  });

  final RentRecord record;
  final String lang;
  final VoidCallback onMarkReturned;

  ({Color colour, String label}) _statusStyle(AppLocalizations loc) {
    final overdue = record.isOverdueAt(DateTime.now());
    if (overdue) {
      return (colour: AppColors.red, label: loc.rent_status_overdue);
    }
    switch (record.status) {
      case RentStatus.returned:
        return (colour: AppColors.green, label: loc.rent_status_returned);
      case RentStatus.overdue:
        return (colour: AppColors.red, label: loc.rent_status_overdue);
      case RentStatus.active:
        return (colour: AppColors.gold, label: loc.rent_status_active);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final style = _statusStyle(loc);
    final isOut = record.direction == RentDirection.out_;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isOut ? AppColors.orangeSoft : AppColors.indigoSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOut
                        ? AppColors.orangeGlow
                        : AppColors.indigo.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  isOut ? Icons.upload_outlined : Icons.download_outlined,
                  color: isOut ? AppColors.orange : AppColors.indigo,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.counterpartyName,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.gearName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.gearName!,
                        style: TextStyle(
                          color: AppColors.filmDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                BookingFormat.money(
                  record.amount,
                  lang: lang,
                  bnNumerals: lang == 'bn',
                ),
                style: TextStyle(
                  color: AppColors.gold,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: style.colour.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: style.colour.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    color: style.colour,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (record.returnBy != null)
                Expanded(
                  child: Text(
                    BookingFormat.dateTime(record.returnBy!, lang: lang),
                    style: TextStyle(
                      color: AppColors.filmMuted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (record.status == RentStatus.active)
                TextButton(
                  onPressed: onMarkReturned,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    loc.rent_mark_returned,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
