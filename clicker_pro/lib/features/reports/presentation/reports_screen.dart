// lib/features/reports/presentation/reports_screen.dart
//
// Reports dashboard.  Layout:
//
//   ┌────────────────────────────┐
//   │ AppBar: ← Reports          │
//   ├────────────────────────────┤
//   │ Year selector (pills)      │
//   ├────────────────────────────┤
//   │ Yearly summary card        │
//   │   Revenue | Expenses       │
//   │   Payouts | Net profit     │
//   ├────────────────────────────┤
//   │ Team performance section   │
//   │   #1  Alice  …             │
//   │   #2  Bob    …             │
//   └────────────────────────────┘
//
// Pull-to-refresh invalidates both `yearlySummaryProvider` and
// `teamPerformanceProvider` for the active year so a single gesture
// re-runs both backend calls in parallel।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../application/reports_providers.dart';
import 'widgets/team_performance_section.dart';
import 'widgets/year_selector.dart';
import 'widgets/yearly_summary_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final year = ref.watch(selectedYearProvider);

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
          loc.reports_title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () async {
          // Refresh both data providers for the active year.  We
          // invalidate by re-reading the family argument, which is the
          // recommended Riverpod idiom for FutureProvider.family।
          ref.invalidate(yearlySummaryProvider(year));
          ref.invalidate(teamPerformanceProvider(year));
          // Tiny delay so the spinner shows even on instant cache hits।
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 8),
            YearSelector(),
            YearlySummaryCard(),
            TeamPerformanceSection(),
          ],
        ),
      ),
    );
  }
}
