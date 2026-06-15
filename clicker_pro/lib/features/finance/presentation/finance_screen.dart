// lib/features/finance/presentation/finance_screen.dart
//
// Finance Dashboard — "Aura" bento layout on the warm-porcelain theme.
//
// Visual language (adapted from the Aura Mobile Finance reference):
//   • Big-figure hero card (gradient, oversized Net, mono eyebrow label)
//   • Circular quick-action pills under the hero
//   • "Assets"-style rows for Booked / Collected / Due
//   • Income vs Expense bento pair with share bars
//   • 6-month bar chart card
//   • "Activity Log" — events with money still owed, transaction-style
//   • Staggered fade-up entrance, large radii, pill controls
//
// All figures derive from the local booking stream + expense list so the
// screen works offline. Manager role gets the locked view (due + client
// only — no income/profit) per the permission matrix.

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
import '../../profile/application/profile_controllers.dart';

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
    final firstName = ref
            .watch(currentUserProvider)
            .valueOrNull
            ?.name
            .trim()
            .split(' ')
            .first ??
        '';

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

    final periodBookings = bookings
        .where((b) => b.status != BookingStatus.cancelled && inPeriod(b.date))
        .toList(growable: false);
    final booked = periodBookings.fold<double>(
      0,
      (s, b) => s + (b.customPrice ?? 0),
    );

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
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstName.isNotEmpty)
              Text(
                'Hello, $firstName',
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              'Finance',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(dueBreakdownProvider);
          await ref.read(expenseListControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            _FadeUp(order: 0, child: _buildPeriodToggle()),
            const SizedBox(height: 14),
            if (isManager) ...[
              _FadeUp(order: 1, child: _managerLockedNotice()),
              const SizedBox(height: 18),
            ] else ...[
              _FadeUp(
                order: 1,
                child: _buildHero(net: net, collected: collected),
              ),
              const SizedBox(height: 18),
              _FadeUp(order: 2, child: _buildQuickActions(isManager)),
              const SizedBox(height: 22),
              _FadeUp(
                order: 3,
                child: _buildIncomeExpensePair(
                  income: collected,
                  expense: periodExpense,
                ),
              ),
              const SizedBox(height: 14),
              _FadeUp(
                order: 4,
                child: _buildAssetRows(
                  booked: booked,
                  collected: collected,
                  due: periodDue,
                ),
              ),
              const SizedBox(height: 14),
              _FadeUp(order: 5, child: _buildBarChart(bookings, expenses)),
              const SizedBox(height: 22),
            ],
            _FadeUp(order: 6, child: _buildActivityLog(periodDueEntries)),
          ],
        ),
      ),
    );
  }

  // ── Monthly | Yearly pill ───────────────────────────────────────────
  Widget _buildPeriodToggle() {
    Widget pill(String label, bool yearly) {
      final selected = _isYearly == yearly;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _isYearly = yearly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.film : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.filmDim,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(children: [pill('Monthly', false), pill('Yearly', true)]),
    );
  }

  Widget _managerLockedNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Income/profit are hidden for the Manager role — only dues and clients.',
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

  // ── Hero: oversized Net on a deep gradient card ─────────────────────
  Widget _buildHero({required double net, required double collected}) {
    final positive = net >= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        gradient: AppColors.drawerHeaderGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary600.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isYearly ? 'NET — THIS YEAR' : 'NET — THIS MONTH',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10.5,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '৳${net.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                height: 1.04,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Collected ৳${collected.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Circular quick-action pills ─────────────────────────────────────
  Widget _buildQuickActions(bool isManager) {
    final actions = <({String label, IconData icon, String route})>[
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
        label: 'Staff Pay',
        icon: Icons.groups_outlined,
        route: RouteNames.teamSalarySheet,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(a.route),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14803500),
                            blurRadius: 16,
                            spreadRadius: -4,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(a.icon, color: AppColors.orange, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Income / Expense bento pair ─────────────────────────────────────
  Widget _buildIncomeExpensePair({
    required double income,
    required double expense,
  }) {
    final total = (income + expense) <= 0 ? 1.0 : income + expense;

    Widget card({
      required String label,
      required double value,
      required double share,
      required Color color,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14803500),
                blurRadius: 20,
                spreadRadius: -6,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  letterSpacing: 1.6,
                  color: AppColors.filmDim.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '৳${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.film,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (value / total).clamp(0.02, 1.0),
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          label: 'INCOME',
          value: income,
          share: income / total,
          color: AppColors.green,
          icon: Icons.south_west_rounded,
        ),
        const SizedBox(width: 14),
        card(
          label: 'EXPENSE',
          value: expense,
          share: expense / total,
          color: AppColors.coral,
          icon: Icons.north_east_rounded,
        ),
      ],
    );
  }

  // ── "Assets" rows: Booked / Collected / Due ─────────────────────────
  Widget _buildAssetRows({
    required double booked,
    required double collected,
    required double due,
  }) {
    Widget row({
      required IconData icon,
      required Color color,
      required String label,
      required String sub,
      required double value,
      VoidCallback? onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: AppColors.filmDim.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '৳${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isYearly ? 'THIS YEAR' : 'THIS MONTH',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 1.8,
              color: AppColors.filmDim.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          row(
            icon: Icons.event_note_rounded,
            color: AppColors.film,
            label: 'Booked',
            sub: 'Total booking value',
            value: booked,
          ),
          Divider(height: 1, color: AppColors.hairline),
          row(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.green,
            label: 'Collected',
            sub: 'Collected',
            value: collected,
          ),
          Divider(height: 1, color: AppColors.hairline),
          row(
            icon: Icons.hourglass_bottom_rounded,
            color: AppColors.coral,
            label: 'Due',
            sub: 'Due — see the Activity Log below',
            value: due,
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LAST 6 MONTHS',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  letterSpacing: 1.8,
                  color: AppColors.filmDim.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _legendDot(AppColors.orange, 'Income'),
              const SizedBox(width: 10),
              _legendDot(AppColors.coral, 'Expense'),
            ],
          ),
          const SizedBox(height: 16),
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
                          _bar(incomeH, AppColors.orange),
                          const SizedBox(width: 3),
                          _bar(expenseH, AppColors.coral),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        monthNames[m.month - 1],
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
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
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: 10,
      height: height.clamp(3, 90),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  // ── Activity Log: events with money still owed ──────────────────────
  Widget _buildActivityLog(List<DueEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'ACTIVITY LOG — DUE',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10.5,
              letterSpacing: 1.8,
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              'No dues 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entries.length && i < 10; i++) ...[
                  _activityRow(entries[i]),
                  if (i != entries.length - 1 && i != 9)
                    Divider(height: 1, indent: 68, color: AppColors.hairline),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _activityRow(DueEntry e) {
    final display = e.clientName?.trim().isNotEmpty == true
        ? e.clientName!
        : e.title;
    final initial = display.isEmpty ? '?' : display[0].toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(
        context,
      ).pushNamed(RouteNames.bookingDetail, arguments: e.bookingId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.date.day}/${e.date.month}/${e.date.year}'
                    ' · Paid ৳${e.paid.toStringAsFixed(0)} / ৳${e.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-৳${e.due.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.coral,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered fade-up entrance: each [order] step starts 70ms later.
class _FadeUp extends StatefulWidget {
  const _FadeUp({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<_FadeUp> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + widget.order * 70), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      offset: _shown ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        opacity: _shown ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
