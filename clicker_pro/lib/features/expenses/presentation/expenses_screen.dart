// lib/features/expenses/presentation/expenses_screen.dart
//
// Expenses module entry point।  Layout:
//
//   ┌─────────────────────────────┐
//   │ AppBar: ← Expenses          │
//   ├─────────────────────────────┤
//   │ ProfitLossCard              │
//   │   Income | Expense | Net    │
//   ├─────────────────────────────┤
//   │ ListView                    │
//   │   ExpenseRow                │
//   │   ExpenseRow                │
//   │   ...                       │
//   ├─────────────────────────────┤
//   │ FAB:  + (record expense)    │
//   └─────────────────────────────┘
//
// Refresh handling:
//   - Pull-to-refresh on the list re-fetches both list + P&L।
//   - After a successful add, the controller invalidates
//     `profitLossProvider` so the totals refresh automatically।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/expense_providers.dart';
import 'dialogs/add_expense_sheet.dart';
import 'widgets/expense_row.dart';
import 'widgets/profit_loss_card.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(expenseListControllerProvider);

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
          loc.expenses_title,
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
          await ref.read(expenseListControllerProvider.notifier).refresh();
          ref.invalidate(profitLossProvider);
        },
        child: CustomScrollView(
          // `AlwaysScrollable...` so the pull-to-refresh works even when
          // the list is empty (otherwise the empty state can't be pulled)।
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: ProfitLossCard()),
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: loc.expenses_load_failed,
                  onRetry: () => ref
                      .read(expenseListControllerProvider.notifier)
                      .refresh(),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message:
                          '${loc.expenses_empty_title}\n'
                          '${loc.expenses_empty_subtitle}',
                      icon: Icons.payments_outlined,
                      actionLabel: loc.expenses_add,
                      onAction: () => AddExpenseSheet.show(context),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => StaggeredList.item(
                    i,
                    ExpenseRow(expense: items[i], lang: lang),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (items) => items.isEmpty
            ? null // empty state already exposes the "Add" affordance
            : FloatingActionButton.extended(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                onPressed: () => AddExpenseSheet.show(context),
                icon: const Icon(Icons.add),
                label: Text(loc.expenses_add_short),
              ),
        orElse: () => null,
      ),
    );
  }
}
