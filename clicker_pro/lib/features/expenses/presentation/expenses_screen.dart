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

import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'web_expenses.dart';
import 'widgets/expense_row.dart';
import 'widgets/profit_loss_card.dart';
import '../../../theme/app_theme.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  // Active category filter — null means "All". Compared case-insensitively
  // against each expense's free-form category string.
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(expenseListControllerProvider);

    // On wide web the WebNavShell owns the chrome; render the dedicated desktop
    // expenses view instead of the mobile body. Mobile + narrow web unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: WebExpenses(onLogExpense: () => AddExpenseSheet.show(context)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          loc.expenses_title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.orange,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await ref
                    .read(expenseListControllerProvider.notifier)
                    .refresh();
                ref.invalidate(profitLossProvider);
              },
              child: CustomScrollView(
                // `AlwaysScrollable...` so the pull-to-refresh works even
                // when the list is empty.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: ProfitLossCard()),
                  async.maybeWhen(
                    data: (items) {
                      final categories = <String>{
                        for (final e in items)
                          if (e.category.trim().isNotEmpty) e.category.trim(),
                      }.toList()..sort();
                      if (categories.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      }
                      return SliverToBoxAdapter(
                        child: _CategoryChips(
                          categories: categories,
                          active: _filter,
                          onSelect: (c) => setState(() => _filter = c),
                        ),
                      );
                    },
                    orElse: () =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
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
                      final filtered = _filter == null
                          ? items
                          : [
                              for (final e in items)
                                if (e.category.trim().toLowerCase() ==
                                    _filter!.toLowerCase())
                                  e,
                            ];
                      return SliverPadding(
                        padding: const EdgeInsets.only(top: 4),
                        sliver: SliverList.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => StaggeredList.item(
                            i,
                            ExpenseRow(expense: filtered[i], lang: lang),
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
                ],
              ),
            ),
          ),
          // Inline "Add Expense" bar (.dc.html) — replaces the floating FAB,
          // hidden on the empty state (which has its own Add affordance).
          async.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => AddExpenseSheet.show(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(
                            loc.expenses_add,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Horizontal category filter chips (.dc.html): "All" (solid orange when
/// active) plus one pill per category (white + hairline when inactive).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.active,
    required this.onSelect,
  });

  final List<String> categories;
  final String? active;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? null
                  : Border.all(color: AppColors.line(0.1)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 6, 11, 6),
        children: [
          chip('All', active == null, () => onSelect(null)),
          for (final c in categories)
            chip(c, active == c, () => onSelect(c)),
        ],
      ),
    );
  }
}
