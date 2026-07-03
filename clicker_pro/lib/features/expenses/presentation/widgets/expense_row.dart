// lib/features/expenses/presentation/widgets/expense_row.dart
//
// Single row in the expense list (.dc.html MOD-18): a category-coloured
// icon tile, the note/category as title + meta, and the amount in red
// with the date underneath. An attached receipt shows a small paperclip.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/expense.dart';
import '../../../../theme/app_theme.dart';

/// Maps a free-form category string to an icon + soft/saturated colour pair,
/// keyed on keywords so studio-invented categories still get a sensible look.
({IconData icon, Color bg, Color fg}) expenseCatStyle(String category) {
  final c = category.toLowerCase();
  if (c.contains('transport') ||
      c.contains('travel') ||
      c.contains('taxi') ||
      c.contains('fuel')) {
    return (
      icon: Icons.local_taxi_rounded,
      bg: AppColors.purpleSoft,
      fg: AppColors.purple,
    );
  }
  if (c.contains('food') || c.contains('lunch') || c.contains('meal')) {
    return (
      icon: Icons.restaurant_rounded,
      bg: AppColors.orangeSoft,
      fg: AppColors.primary700,
    );
  }
  if (c.contains('print') || c.contains('album')) {
    return (
      icon: Icons.print_rounded,
      bg: AppColors.greenSoft,
      fg: AppColors.green,
    );
  }
  if (c.contains('equip') || c.contains('gear') || c.contains('rent')) {
    return (
      icon: Icons.photo_camera_rounded,
      bg: AppColors.goldSoft,
      fg: AppColors.gold,
    );
  }
  return (
    icon: Icons.payments_rounded,
    bg: AppColors.line(0.05),
    fg: AppColors.filmDim,
  );
}

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key, required this.expense, required this.lang});

  final Expense expense;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final style = expenseCatStyle(expense.category);
    final hasReceipt = (expense.receiptUrl ?? '').isNotEmpty;
    final meta = <String>[
      expense.category,
      if ((expense.note ?? '').isNotEmpty) expense.note!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(style.icon, color: style.fg, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (expense.note?.isNotEmpty ?? false)
                      ? expense.note!
                      : expense.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.filmMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (hasReceipt) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.attach_file_rounded,
                        size: 12,
                        color: AppColors.orange,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                BookingFormat.money(
                  expense.amount,
                  lang: lang,
                  bnNumerals: lang == 'bn',
                ),
                style: TextStyle(
                  color: AppColors.red,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                DateFormat('MMM d').format(expense.incurredAt),
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
