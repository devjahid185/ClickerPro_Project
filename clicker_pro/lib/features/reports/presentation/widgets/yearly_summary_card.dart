// lib/features/reports/presentation/widgets/yearly_summary_card.dart
//
// Year-scoped P&L summary card.  Four metrics: revenue, expenses,
// freelancer payouts, net profit।  Layout: 2×2 grid so each metric
// has breathing room and the card stays readable on phones।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/reports_providers.dart';
import '../../../../theme/app_theme.dart';

class YearlySummaryCard extends ConsumerWidget {
  const YearlySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final year = ref.watch(selectedYearProvider);

    if (year == 0) {
      // All-time selected — yearly summary endpoint requires a real year.
      return _Card(
        title: loc.reports_summary_section,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            loc.reports_summary_only_for_year,
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final async = ref.watch(yearlySummaryProvider(year));

    return _Card(
      title: '${loc.reports_summary_section} • $year',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: LensLoader(size: 22)),
        ),
        error: (_, _) => Text(
          loc.reports_summary_load_failed,
          style: TextStyle(color: AppColors.red, fontSize: 13),
        ),
        data: (s) {
          String fmt(double v) =>
              BookingFormat.money(v, lang: lang, bnNumerals: lang == 'bn');
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: loc.reports_revenue,
                      value: fmt(s.totalRevenue),
                      colour: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: loc.reports_expenses,
                      value: fmt(s.totalExpenses),
                      colour: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: loc.reports_payouts,
                      value: fmt(s.totalFreelancerPayouts),
                      colour: AppColors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: loc.reports_net_profit,
                      value: fmt(s.netProfit),
                      colour: s.netProfit < 0 ? AppColors.red : AppColors.gold,
                      emphasised: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.gold,
              fontFamily: AppText.brandFontFamily,
              fontSize: 14,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
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
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color colour;
  final bool emphasised;

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
            fontSize: emphasised ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
