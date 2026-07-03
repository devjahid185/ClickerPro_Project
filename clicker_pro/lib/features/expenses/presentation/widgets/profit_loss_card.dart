// lib/features/expenses/presentation/widgets/profit_loss_card.dart
//
// Top-of-screen P&L summary card.  Shows three metrics — income,
// expense, net — pulled from `profitLossProvider`.  The "net" tile
// flips colour to red when negative so the studio operator can spot a
// loss at a glance।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/expense_providers.dart';
import '../../../../theme/app_theme.dart';

class ProfitLossCard extends ConsumerWidget {
  const ProfitLossCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(profitLossProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.expenses_pl_card_title.toUpperCase(),
            style: TextStyle(
              color: AppColors.orange,
              fontFamily: AppText.monoFontFamily,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LensLoader(size: 22),
              ),
            ),
            error: (_, _) => Text(
              loc.expenses_pl_load_failed,
              style: TextStyle(color: AppColors.red, fontSize: 13),
            ),
            data: (pl) {
              return Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: loc.expenses_pl_income,
                      value: BookingFormat.money(
                        pl.totalIncome,
                        lang: lang,
                        bnNumerals: lang == 'bn',
                      ),
                      colour: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: loc.expenses_pl_expense,
                      value: BookingFormat.money(
                        pl.totalExpense,
                        lang: lang,
                        bnNumerals: lang == 'bn',
                      ),
                      colour: AppColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: loc.expenses_pl_net,
                      value: BookingFormat.money(
                        pl.netProfit,
                        lang: lang,
                        bnNumerals: lang == 'bn',
                      ),
                      // Negative net → red, otherwise gold
                      colour: pl.netProfit < 0 ? AppColors.red : AppColors.gold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.filmMuted,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colour,
            fontFamily: AppText.brandFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
