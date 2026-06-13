// lib/features/expenses/presentation/widgets/expense_row.dart
//
// Single row in the expense list — left side icon + category + note,
// right side amount + date.  Designed to be lazy-list-friendly: no
// ConsumerWidget inheritance, no async lookups inside the row builder।

import 'package:flutter/material.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/expense.dart';

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key, required this.expense, required this.lang});

  final Expense expense;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar-style category badge
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.orangeGlow),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.note!,
                    style: TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  BookingFormat.dateTime(expense.incurredAt, lang: lang),
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            BookingFormat.money(
              expense.amount,
              lang: lang,
              bnNumerals: lang == 'bn',
            ),
            style: const TextStyle(
              color: AppColors.red,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
