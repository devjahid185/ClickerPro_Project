// test/expenses/expenses_screen_smoke_test.dart
//
// Smoke for the new ExpensesScreen.  Stubs the repository so we don't
// hit the network, asserts:
//
//   • header renders
//   • profit-loss card renders income / expense / net values
//   • empty list renders the EmptyState
//   • non-empty list renders rows + the "Add" FAB
//
// Repository is overridden via Riverpod, no real DB or http involved।

import 'package:clicker_pro/features/expenses/application/expense_providers.dart';
import 'package:clicker_pro/features/expenses/domain/expense.dart';
import 'package:clicker_pro/features/expenses/domain/expense_repository.dart';
import 'package:clicker_pro/features/expenses/domain/profit_loss.dart';
import 'package:clicker_pro/features/expenses/presentation/expenses_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExpenseRepo implements ExpenseRepository {
  _FakeExpenseRepo({this.expenses = const <Expense>[], required this.pl});

  final List<Expense> expenses;
  final ProfitLoss pl;
  final List<Expense> created = <Expense>[];

  @override
  Future<List<Expense>> list() async => List.of(expenses);

  @override
  Future<Expense> create(Expense draft) async {
    final saved = draft.copyWith(id: 'srv-${created.length + 1}');
    created.add(saved);
    return saved;
  }

  @override
  Future<ProfitLoss> profitLoss() async => pl;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ExpenseRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExpensesScreen(),
      ),
    ),
  );
  await tester.pump(); // initial frame
  await tester.pump(const Duration(milliseconds: 50)); // settle Async
}

void main() {
  testWidgets('renders empty state when no expenses', (tester) async {
    final repo = _FakeExpenseRepo(
      expenses: const <Expense>[],
      pl: const ProfitLoss(totalIncome: 0, totalExpense: 0, netProfit: 0),
    );

    await _pumpScreen(tester, repo: repo);

    // Header
    expect(find.text('Expenses'), findsOneWidget);
    // P&L card title
    expect(find.text('Profit & Loss'), findsOneWidget);
    // Empty state copy
    expect(find.textContaining('No expenses yet'), findsOneWidget);
    // FAB hidden when empty (CTA inside the empty state instead)
    expect(find.text('Add'), findsNothing);
  });

  testWidgets('renders rows + FAB when expenses exist', (tester) async {
    final repo = _FakeExpenseRepo(
      expenses: <Expense>[
        Expense(
          id: 'e1',
          category: 'Travel',
          amount: 1500,
          incurredAt: DateTime(2025, 6, 1),
          note: 'Fuel',
        ),
        Expense(
          id: 'e2',
          category: 'Equipment',
          amount: 75000,
          incurredAt: DateTime(2025, 5, 15),
        ),
      ],
      pl: const ProfitLoss(
        totalIncome: 200000,
        totalExpense: 76500,
        netProfit: 123500,
      ),
    );

    await _pumpScreen(tester, repo: repo);

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);
    // FAB visible because list is non-empty
    expect(find.text('Add'), findsOneWidget);
    // P&L metrics — income / expense / net labels render
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('EXPENSE'), findsOneWidget);
    expect(find.text('NET'), findsOneWidget);
  });
}
