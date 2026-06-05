// test/reports/reports_screen_smoke_test.dart
//
// Smoke for the new ReportsScreen.  Stubs the repository so we can
// verify:
//
//   • header renders
//   • year selector renders pills (current year + All time)
//   • summary card renders revenue / expenses / payouts / net labels
//     for a real-year selection
//   • team performance section renders ranked rows
//   • year=0 (All time) hides the yearly summary metrics and shows
//     the "pick a year" hint
//
// Repository overridden via Riverpod, no real DB / http involved।

import 'package:clicker_pro/features/reports/application/reports_providers.dart';
import 'package:clicker_pro/features/reports/domain/reports_repository.dart';
import 'package:clicker_pro/features/reports/domain/team_performance_entry.dart';
import 'package:clicker_pro/features/reports/domain/yearly_summary.dart';
import 'package:clicker_pro/features/reports/presentation/reports_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReportsRepo implements ReportsRepository {
  _FakeReportsRepo({required this.summary, required this.team});

  final YearlySummary summary;
  final List<TeamPerformanceEntry> team;

  @override
  Future<YearlySummary> yearlySummary(int year) async => summary;

  @override
  Future<List<TeamPerformanceEntry>> teamPerformance(int year) async => team;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ReportsRepository repo,
  int? overrideYear,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repo),
        if (overrideYear != null)
          selectedYearProvider.overrideWith((_) => overrideYear),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReportsScreen(),
      ),
    ),
  );
  await tester.pump(); // initial frame
  await tester.pump(const Duration(milliseconds: 50)); // settle Async
}

void main() {
  testWidgets('renders summary + team rows for the current year', (
    tester,
  ) async {
    final repo = _FakeReportsRepo(
      summary: const YearlySummary(
        year: '2025',
        totalRevenue: 500000,
        totalExpenses: 80000,
        totalFreelancerPayouts: 120000,
        netProfit: 300000,
      ),
      team: const [
        TeamPerformanceEntry(
          userId: 'u1',
          name: 'Alice',
          role: 'FREELANCER',
          totalEvents: 5,
          totalEarnings: 50000,
          pendingReEdits: 0,
          performanceScore: 50,
        ),
        TeamPerformanceEntry(
          userId: 'u2',
          name: 'Bob',
          role: 'MANAGER',
          totalEvents: 2,
          totalEarnings: 10000,
          pendingReEdits: 1,
          performanceScore: 15,
        ),
      ],
    );

    await _pumpScreen(tester, repo: repo);

    // AppBar
    expect(find.text('Reports'), findsOneWidget);
    // Year pill includes "All time"
    expect(find.text('All time'), findsOneWidget);
    // Summary card metric labels render
    expect(find.text('REVENUE'), findsOneWidget);
    expect(find.text('EXPENSES'), findsOneWidget);
    expect(find.text('FREELANCER PAYOUTS'), findsOneWidget);
    expect(find.text('NET PROFIT'), findsOneWidget);
    // Team rows render
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    // Score chips
    expect(find.text('50'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('All time selection hides yearly metrics, shows hint', (
    tester,
  ) async {
    final repo = _FakeReportsRepo(
      summary: const YearlySummary(
        year: '',
        totalRevenue: 0,
        totalExpenses: 0,
        totalFreelancerPayouts: 0,
        netProfit: 0,
      ),
      team: const [],
    );

    await _pumpScreen(tester, repo: repo, overrideYear: 0);

    // Hint appears
    expect(find.textContaining('Pick a specific year'), findsOneWidget);
    // Metric labels NOT rendered (yearly summary card collapsed)
    expect(find.text('REVENUE'), findsNothing);
    expect(find.text('NET PROFIT'), findsNothing);
    // Team empty state
    expect(find.text('No team members yet'), findsOneWidget);
  });
}
