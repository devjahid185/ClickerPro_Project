// lib/features/expenses/presentation/web_expenses.dart
//
// Graphy7 — WEB-ONLY expenses (Graphy7 Design).
//
// A desktop expenses view, rendered ONLY on wide web. The mobile expenses body
// is 100% untouched (ExpensesScreen routes here only when
// kIsWeb && width >= 900). Ported from the design source's "Expenses" screen: a
// pair of summary cards (spent this month / total tracked) beside a "Recent
// Expenses" list, each row carrying a category icon, note, and amount.
//
// Data comes from the same `expenseListControllerProvider` the mobile screen
// uses — no new business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/currency.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';

/// The wide-web expenses view. Pure presentation over the existing providers.
class WebExpenses extends ConsumerWidget {
  const WebExpenses({super.key, this.onLogExpense});

  final VoidCallback? onLogExpense;

  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseListControllerProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(child: _Header(onLog: onLogExpense)),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: async.when(
                loading: () => const _Body(
                  summary: _SummarySkeleton(),
                  list: _ListSkeleton(),
                ),
                error: (_, _) => const _Message(
                  text: 'Could not load expenses.',
                ),
                data: (all) {
                  if (all.isEmpty) {
                    return const _Message(text: 'No expenses logged yet.');
                  }
                  final now = DateTime.now();
                  final month = all.where((e) =>
                      e.incurredAt.year == now.year &&
                      e.incurredAt.month == now.month);
                  final monthTotal =
                      month.fold<double>(0, (s, e) => s + e.amount);
                  final allTotal =
                      all.fold<double>(0, (s, e) => s + e.amount);
                  final recent = [...all]
                    ..sort((a, b) => b.incurredAt.compareTo(a.incurredAt));
                  return _Body(
                    summary: _SummaryCards(
                      monthTotal: monthTotal,
                      allTotal: allTotal,
                      monthName: DateFormat.MMMM().format(now),
                      monthCount: month.length,
                    ),
                    list: _ExpenseList(rows: recent.take(12).toList()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({this.onLog});
  final VoidCallback? onLog;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Expenses',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: WebTheme.ink,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Track spending across the studio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (onLog != null) ...[
          const SizedBox(width: WebTheme.sp4),
          WebHoverLift(
            onTap: onLog,
            borderRadius: WebTheme.rButton,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
              decoration: BoxDecoration(
                color: WebTheme.orange,
                borderRadius: BorderRadius.circular(WebTheme.rButton),
                boxShadow: [
                  BoxShadow(
                    color: WebTheme.orange.withValues(alpha: 0.42),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Log Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Responsive two-column body: summary cards beside the recent list; stacks on
/// narrow widths.
class _Body extends StatelessWidget {
  const _Body({required this.summary, required this.list});
  final Widget summary;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [summary, const SizedBox(height: WebTheme.sp4), list],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 300, child: summary),
            const SizedBox(width: WebTheme.sp4),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────── SUMMARY CARDS
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.monthTotal,
    required this.allTotal,
    required this.monthName,
    required this.monthCount,
  });

  final double monthTotal;
  final double allTotal;
  final String monthName;
  final int monthCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatCard(
          label: 'SPENT · ${monthName.toUpperCase()}',
          value: _formatBdt((monthTotal * 100).round()),
          sub: monthCount == 1 ? '1 expense' : '$monthCount expenses',
          valueColor: WebTheme.danger,
          filled: true,
        ),
        const SizedBox(height: WebTheme.sp4),
        _StatCard(
          label: 'TOTAL TRACKED',
          value: _formatBdt((allTotal * 100).round()),
          sub: 'all time',
          valueColor: WebTheme.ink,
          filled: false,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
    required this.filled,
  });

  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.sp5),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: WebTheme.mono,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: WebTheme.inkFaint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: valueColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: WebTheme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── EXPENSE LIST
class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.rows});
  final List<Expense> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 15),
            child: Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: WebTheme.ink,
              ),
            ),
          ),
          const Divider(height: 1, color: WebTheme.hairline),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: WebTheme.hairline),
            _ExpenseRow(expense: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;

  /// Maps a free-form category string to an icon + accent.
  (IconData, Color) get _cat {
    final c = expense.category.toLowerCase();
    if (c.contains('gear') || c.contains('equip')) {
      return (Icons.photo_camera_rounded, WebTheme.orange);
    }
    if (c.contains('travel') || c.contains('transport')) {
      return (Icons.local_taxi_rounded, WebTheme.info);
    }
    if (c.contains('food') || c.contains('meal')) {
      return (Icons.restaurant_rounded, WebTheme.warning);
    }
    if (c.contains('studio') || c.contains('rent')) {
      return (Icons.home_work_rounded, WebTheme.teal);
    }
    if (c.contains('print') || c.contains('album') || c.contains('product')) {
      return (Icons.menu_book_rounded, WebTheme.success);
    }
    return (Icons.receipt_long_rounded, WebTheme.inkMuted);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _cat;
    final title = (expense.note?.trim().isNotEmpty ?? false)
        ? expense.note!.trim()
        : expense.category;
    final date = DateFormat('d MMM').format(expense.incurredAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(WebTheme.rChip),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.category} · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '−${_formatBdt((expense.amount * 100).round())}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: WebTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            margin: EdgeInsets.only(bottom: i == 0 ? WebTheme.sp4 : 0),
            padding: const EdgeInsets.all(WebTheme.sp5),
            decoration: BoxDecoration(
              color: WebTheme.surface,
              borderRadius: BorderRadius.circular(WebTheme.rPanel),
              border: Border.all(color: WebTheme.hairline),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebShimmer(width: 90, height: 10, borderRadius: 4),
                SizedBox(height: 12),
                WebShimmer(width: 120, height: 26, borderRadius: 6),
              ],
            ),
          ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Column(
        children: List.generate(
          5,
          (i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                WebShimmer(width: 40, height: 40, borderRadius: WebTheme.rChip),
                SizedBox(width: 13),
                Expanded(child: WebShimmer(height: 14, borderRadius: 6)),
                SizedBox(width: 40),
                WebShimmer(width: 60, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
String _formatBdt(int minor) {
  final taka = (minor / 100).round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}
