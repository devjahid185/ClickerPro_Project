// lib/features/finance/presentation/finance_screen.dart
//
// Finance Dashboard — the role-aware money home (v12 "Finance 4-Role").
//
// Layout:
//   ┌─────────────────────────────────┐
//   │ Monthly | Yearly toggle         │
//   │ Income · Expense · Net cards    │
//   │ 6-month Income vs Expense bars  │
//   │ Booked · Collected · Due strip  │
//   │ Events with due (tap → details) │
//   │ Quick links (Expenses, CashFlow,│
//   │   Petty Cash, Reports, Salary)  │
//   └─────────────────────────────────┘
//
// Numbers are derived from the local booking stream + expense list so
// the screen works offline; Manager role gets the locked view (due +
// client only, no income/profit) per the permission matrix.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/navigation/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../auth/domain/user_role.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/domain/expense.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(bookingsPolicyProvider);
    final isManager = policy.role == UserRole.manager;

    final bookings =
        ref.watch(bookingListProvider(const BookingFilter())).valueOrNull ??
        const <Booking>[];
    final expenses =
        ref.watch(expenseListControllerProvider).valueOrNull ??
        const <Expense>[];
    final dueEntries = ref.watch(dueBreakdownProvider).valueOrNull;

    final now = DateTime.now();
    bool inPeriod(DateTime d) => _isYearly
        ? d.year == now.year
        : (d.year == now.year && d.month == now.month);

    // Booked = priced, non-cancelled bookings in the period.
    final periodBookings = bookings
        .where((b) => b.status != BookingStatus.cancelled && inPeriod(b.date))
        .toList(growable: false);
    final booked = periodBookings.fold<double>(
      0,
      (s, b) => s + (b.customPrice ?? 0),
    );

    // Due per booking comes from the payment aggregates; bookings absent
    // from the due list are fully collected.
    final dueById = <String, double>{
      for (final e in dueEntries ?? const <DueEntry>[]) e.bookingId: e.due,
    };
    final periodDue = periodBookings.fold<double>(
      0,
      (s, b) => s + (dueById[b.id] ?? 0),
    );
    final collected = booked - periodDue;

    final periodExpense = expenses
        .where((e) => inPeriod(e.incurredAt))
        .fold<double>(0, (s, e) => s + e.amount);
    final net = collected - periodExpense;

    final periodDueEntries = (dueEntries ?? const <DueEntry>[])
        .where((e) => inPeriod(e.date))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Finance',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: AppColors.voidLight,
        onRefresh: () async {
          ref.invalidate(dueBreakdownProvider);
          await ref.read(expenseListControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _buildPeriodToggle(),
            const SizedBox(height: 14),
            if (isManager)
              _managerLockedNotice()
            else ...[
              _buildHeroCards(
                income: collected,
                expense: periodExpense,
                net: net,
              ),
              const SizedBox(height: 16),
              _buildBarChart(bookings, expenses),
              const SizedBox(height: 16),
              _buildBookedRow(
                booked: booked,
                collected: collected,
                due: periodDue,
              ),
              const SizedBox(height: 18),
            ],
            _buildDueSection(periodDueEntries),
            const SizedBox(height: 18),
            _buildQuickLinks(isManager),
          ],
        ),
      ),
    );
  }

  // ── Monthly | Yearly ────────────────────────────────────────────────
  Widget _buildPeriodToggle() {
    Widget pill(String label, bool yearly) {
      final selected = _isYearly == yearly;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _isYearly = yearly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.voidBlack : AppColors.filmDim,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(children: [pill('Monthly', false), pill('Yearly', true)]),
    );
  }

  Widget _managerLockedNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Manager role-এ income/profit দেখা যায় না — শুধু বকেয়া ও ক্লায়েন্ট।',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.9),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Income / Expense / Net ─────────────────────────────────────────
  Widget _buildHeroCards({
    required double income,
    required double expense,
    required double net,
  }) {
    Widget card(String label, double value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.voidLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '৳${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.8),
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('INCOME', income, AppColors.teal, Icons.trending_up_rounded),
        const SizedBox(width: 10),
        card('EXPENSE', expense, AppColors.coral, Icons.trending_down_rounded),
        const SizedBox(width: 10),
        card(
          'NET',
          net,
          net >= 0 ? AppColors.gold : AppColors.red,
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  // ── 6-month Income vs Expense bars ─────────────────────────────────
  Widget _buildBarChart(List<Booking> bookings, List<Expense> expenses) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return DateTime(m.year, m.month, 1);
    });

    final incomeByMonth = <DateTime, double>{for (final m in months) m: 0};
    final expenseByMonth = <DateTime, double>{for (final m in months) m: 0};

    for (final b in bookings) {
      if (b.status == BookingStatus.cancelled) continue;
      final key = DateTime(b.date.year, b.date.month, 1);
      if (incomeByMonth.containsKey(key)) {
        incomeByMonth[key] = incomeByMonth[key]! + (b.customPrice ?? 0);
      }
    }
    for (final e in expenses) {
      final key = DateTime(e.incurredAt.year, e.incurredAt.month, 1);
      if (expenseByMonth.containsKey(key)) {
        expenseByMonth[key] = expenseByMonth[key]! + e.amount;
      }
    }

    final maxVal = [
      ...incomeByMonth.values,
      ...expenseByMonth.values,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Last 6 Months',
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _legendDot(AppColors.teal, 'Income'),
              const SizedBox(width: 10),
              _legendDot(AppColors.coral, 'Expense'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final incomeH = (incomeByMonth[m]! / maxVal) * 90;
                final expenseH = (expenseByMonth[m]! / maxVal) * 90;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _bar(incomeH, AppColors.teal),
                          const SizedBox(width: 3),
                          _bar(expenseH, AppColors.coral),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        monthNames[m.month - 1],
                        style: TextStyle(
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 10,
      height: height.clamp(2, 90),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.8),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // ── Booked / Collected / Due strip ─────────────────────────────────
  Widget _buildBookedRow({
    required double booked,
    required double collected,
    required double due,
  }) {
    Widget stat(String label, double value, Color color) {
      return Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '৳${value.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.75),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          stat('Booked', booked, AppColors.film),
          Container(width: 1, height: 28, color: AppColors.hairline),
          stat('Collected', collected, AppColors.teal),
          Container(width: 1, height: 28, color: AppColors.hairline),
          stat('Due', due, AppColors.coral),
        ],
      ),
    );
  }

  // ── Events with due ────────────────────────────────────────────────
  Widget _buildDueSection(List<DueEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DUE — ${_isYearly ? 'THIS YEAR' : 'THIS MONTH'}',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10.5,
            letterSpacing: 1.4,
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.voidLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Text(
              'কোনো বকেয়া নেই 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          )
        else
          for (final e in entries.take(8))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.voidLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.hairline),
              ),
              child: ListTile(
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(RouteNames.bookingDetail, arguments: e.bookingId),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.coral,
                    size: 20,
                  ),
                ),
                title: Text(
                  e.clientName?.trim().isNotEmpty == true
                      ? e.clientName!
                      : e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${e.date.day}/${e.date.month}/${e.date.year}'
                  ' · Paid ৳${e.paid.toStringAsFixed(0)}'
                  ' / ৳${e.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
                trailing: Text(
                  '৳${e.due.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  // ── Quick links ────────────────────────────────────────────────────
  Widget _buildQuickLinks(bool isManager) {
    final links = <({String label, IconData icon, String route})>[
      (
        label: 'Expenses',
        icon: Icons.receipt_long_outlined,
        route: RouteNames.financeExpenses,
      ),
      if (!isManager)
        (
          label: 'Cash Flow',
          icon: Icons.stacked_line_chart_rounded,
          route: RouteNames.cashFlow,
        ),
      (
        label: 'Petty Cash',
        icon: Icons.savings_outlined,
        route: RouteNames.pettyCash,
      ),
      if (!isManager)
        (
          label: 'Reports',
          icon: Icons.assessment_outlined,
          route: RouteNames.reports,
        ),
      (
        label: 'Salary Sheet',
        icon: Icons.groups_outlined,
        route: RouteNames.teamSalarySheet,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MORE',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10.5,
            letterSpacing: 1.4,
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: links.map((l) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(l.route),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.voidLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(l.icon, color: AppColors.teal, size: 16),
                    const SizedBox(width: 7),
                    Text(
                      l.label,
                      style: const TextStyle(
                        color: AppColors.film,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
