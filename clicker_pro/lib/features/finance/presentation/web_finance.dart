// lib/features/finance/presentation/web_finance.dart
//
// Graphy7 — WEB-ONLY Finance hub (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 4, MOD-14…22 + 53/54/58/16).
//
// One screen, six live tabs (mono pills, active = orange fill):
//
//   OVERVIEW   — MONTHLY/YEARLY toggle · 3 stat cards (Income gradient /
//                Expense / Net Profit) · Income-vs-Expense 6-month bars ·
//                Client Dues with paid-progress bars + SEND REMINDERS
//   EXPENSES   — 3 summary tiles + list (emoji tile, receipt indicator,
//                category tag, red amount) + "+ Add Expense"
//   CASH FLOW  — next-3-months bars: solid = confirmed income, hatched =
//                pending, tan = projected expense
//   PETTY CASH — balance cards + category-pill entries w/ running balance
//   SALARY     — per-member sheet (events/rate/earned/paid/due) with PAY /
//                PAID ✓ buttons + MARK ALL PAID
//   PAYOUTS    — the existing web payout board (approve/settle requests)
//
// Every number is real: bookings/dues/expenses/petty-cash/payout providers —
// the same ones the mobile Finance screens read. No new business logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/currency.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../bookings/domain/package.dart' as booking_pkg;
import '../../dashboard/application/dashboard_providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/dialogs/add_expense_sheet.dart';
import '../../payments/application/payment_providers.dart' as pay_app;
import '../../petty_cash/domain/petty_cash_entry.dart';
import '../../petty_cash/presentation/petty_cash_screen.dart'
    show pettyCashListProvider, pettyCashBalanceProvider;
import '../../team/application/team_providers.dart';
import '../../team/domain/staff_payout.dart';
import '../../team/presentation/web_payouts.dart';

enum _FinTab { overview, expenses, cashflow, petty, salary, payouts }

extension _FinTabX on _FinTab {
  String get label => switch (this) {
        _FinTab.overview => 'OVERVIEW',
        _FinTab.expenses => 'EXPENSES',
        _FinTab.cashflow => 'CASH FLOW',
        _FinTab.petty => 'PETTY CASH',
        _FinTab.salary => 'SALARY',
        _FinTab.payouts => 'PAYOUTS',
      };
}

/// The wide-web Finance hub. Pure presentation over existing providers.
class WebFinance extends ConsumerStatefulWidget {
  const WebFinance({super.key, this.initialTab = 0});

  /// 0=Overview 1=Expenses 2=Cash Flow 3=Petty 4=Salary 5=Payouts.
  final int initialTab;

  @override
  ConsumerState<WebFinance> createState() => _WebFinanceState();
}

class _WebFinanceState extends ConsumerState<WebFinance> {
  late _FinTab _tab =
      _FinTab.values[widget.initialTab.clamp(0, _FinTab.values.length - 1)];
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          WebEntrance(
            delay: const Duration(milliseconds: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _FinTab.values)
                  _TabPill(
                    label: t.label,
                    active: t == _tab,
                    onTap: () => setState(() => _tab = t),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Re-key so each tab replays its entrance (handoff behavior).
          KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              _FinTab.overview => _OverviewTab(
                  yearly: _yearly,
                  onYearly: (v) => setState(() => _yearly = v),
                ),
              _FinTab.expenses => const _ExpensesTab(),
              _FinTab.cashflow => const _CashFlowTab(),
              _FinTab.petty => const _PettyTab(),
              _FinTab.salary => const _SalaryTab(),
              _FinTab.payouts => const _PayoutsTab(),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TAB PILL
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? WebTheme.orange
              : hovering
                  ? WebTheme.orangeTint
                  : WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
            color: active
                ? WebTheme.orange
                : hovering
                    ? WebTheme.orangeTintBorder
                    : WebTheme.hairline,
          ),
        ),
        child: Text(
          label,
          style: WebTheme.label(
            size: 10,
            tracking: 0.08,
            color: active ? WebTheme.chromeInk : WebTheme.inkMuted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════ TAB 1 OVERVIEW
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.yearly, required this.onYearly});
  final bool yearly;
  final ValueChanged<bool> onYearly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];
    final expenses =
        ref.watch(expenseListControllerProvider).valueOrNull ??
            const <Expense>[];
    final petty =
        ref.watch(pettyCashListProvider).valueOrNull ??
            const <PettyCashEntry>[];
    final dueEntries =
        ref.watch(dueBreakdownProvider).valueOrNull ?? const <DueEntry>[];
    final paymentRecords = ref.watch(pay_app.paymentListControllerProvider).valueOrNull ??
        const [];
    final packages = ref.watch(packagesProvider).valueOrNull ??
        const <booking_pkg.Package>[];
    final packageById = _packageLookup(packages);

    final now = DateTime.now();
    bool inPeriod(DateTime d) => yearly
        ? d.year == now.year
        : (d.year == now.year && d.month == now.month);

    // Same money math as the mobile Finance screen: collected = booked −
    // outstanding dues on the period's bookings; expense includes petty cash.
    final periodBookings = bookings
        .where((b) => b.status != BookingStatus.cancelled && inPeriod(b.date))
        .toList(growable: false);
    final bookingValue = periodBookings.fold<double>(
        0, (s, b) => s + _bookingTotal(b, packageById));
    final collectedFromPayments = paymentRecords
        .where((p) => p.type.toLowerCase() != 'payout' && inPeriod(p.createdAt))
        .fold<double>(0, (s, p) => s + p.amount);
    final booked = bookingValue < collectedFromPayments
        ? collectedFromPayments
        : bookingValue;
    final dueById = {for (final e in dueEntries) e.bookingId: e.due};
    final periodDue =
        periodBookings.fold<double>(0, (s, b) => s + (dueById[b.id] ?? 0));
    final collected = collectedFromPayments > 0
        ? collectedFromPayments
        : booked - periodDue;
    final periodExpense = expenses
            .where((e) => inPeriod(e.incurredAt))
            .fold<double>(0, (s, e) => s + e.amount) +
        petty
            .where((p) => inPeriod(p.date))
            .fold<double>(0, (s, p) => s + p.amount);
    final net = collected - periodExpense;

    final periodLabel = yearly
        ? '${now.year}'
        : DateFormat('MMMM yyyy').format(now).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row: MONTHLY/YEARLY toggle + period label.
        WebEntrance(
          delay: const Duration(milliseconds: 50),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: WebTheme.surface,
                  borderRadius: BorderRadius.circular(WebTheme.rFull),
                  border: Border.all(color: WebTheme.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _segChip('MONTHLY', !yearly, () => onYearly(false)),
                    _segChip('YEARLY', yearly, () => onYearly(true)),
                  ],
                ),
              ),
              const Spacer(),
              Text(periodLabel,
                  style: WebTheme.label(
                      size: 10, color: WebTheme.inkMuted, tracking: 0.08)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // 3 stat cards.
        WebEntrance(
          delay: const Duration(milliseconds: 100),
          child: LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 720;
            final cards = [
              _statCard(
                label: 'INCOME',
                value: _money(collected),
                sub: yearly ? 'collected this year' : 'collected this month',
                gradient: true,
              ),
              _statCard(
                label: 'EXPENSE',
                value: _money(periodExpense),
                sub: 'incl. petty cash',
              ),
              _statCard(
                label: 'NET PROFIT',
                value: _money(net),
                sub: 'income − expense',
                valueColor: WebTheme.success,
                borderColor: WebTheme.successTintBorder,
              ),
            ];
            if (narrow) {
              return Column(children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i != 0) const SizedBox(height: 14),
                  cards[i],
                ],
              ]);
            }
            return Row(children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i != 0) const SizedBox(width: 14),
                Expanded(child: cards[i]),
              ],
            ]);
          }),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 160),
          child: _IncomeExpenseChart(
            bookings: bookings,
            expenses: expenses,
            petty: petty,
            packageById: packageById,
          ),
        ),
        const SizedBox(height: 18),
        WebEntrance(
          delay: const Duration(milliseconds: 220),
          child: _ClientDuesCard(dues: dueEntries),
        ),
      ],
    );
  }

  Widget _segChip(String label, bool active, VoidCallback onTap) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? WebTheme.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
        ),
        child: Text(
          label,
          style: WebTheme.label(
            size: 10,
            tracking: 0.08,
            color: active
                ? WebTheme.chromeInk
                : hovering
                    ? WebTheme.ink
                    : WebTheme.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    bool gradient = false,
    Color? valueColor,
    Color? borderColor,
  }) {
    return _HoverLiftBox(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: gradient ? WebTheme.sunset : null,
          color: gradient ? null : WebTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: gradient
              ? null
              : Border.all(color: borderColor ?? WebTheme.hairline),
          boxShadow: gradient ? WebTheme.orangeGlow : WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: WebTheme.label(
                  size: 9,
                  tracking: 0.18,
                  color: gradient
                      ? WebTheme.onOrangeLabel
                      : WebTheme.inkMuted,
                )),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: WebTheme.displayStyle(
                    size: 30,
                    weight: FontWeight.w800,
                    color: gradient
                        ? WebTheme.chromeInk
                        : (valueColor ?? WebTheme.ink),
                  )),
            ),
            const SizedBox(height: 4),
            Text(sub,
                style: WebTheme.bodyStyle(
                  size: 11,
                  color: gradient
                      ? WebTheme.onOrangeBody
                      : WebTheme.inkMuted,
                )),
          ],
        ),
      ),
    );
  }
}

/// Income vs Expense · 6 months — grouped growing bars.
class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.bookings,
    required this.expenses,
    required this.petty,
    required this.packageById,
  });

  final List<Booking> bookings;
  final List<Expense> expenses;
  final List<PettyCashEntry> petty;
  final Map<String, booking_pkg.Package> packageById;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));

    final income = <double>[];
    final expense = <double>[];
    for (final m in months) {
      income.add(bookings
          .where((b) =>
              b.status != BookingStatus.cancelled &&
              b.date.year == m.year &&
              b.date.month == m.month)
          .fold<double>(0, (s, b) => s + _bookingTotal(b, packageById)));
      expense.add(expenses
              .where((e) =>
                  e.incurredAt.year == m.year &&
                  e.incurredAt.month == m.month)
              .fold<double>(0, (s, e) => s + e.amount) +
          petty
              .where((p) =>
                  p.date.year == m.year && p.date.month == m.month)
              .fold<double>(0, (s, p) => s + p.amount));
    }
    final maxV = [
      ...income,
      ...expense,
    ].fold<double>(1, (mx, v) => v > mx ? v : mx);

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Income vs Expense · 6 months',
                  style: WebTheme.displayStyle(size: 16)),
              const Spacer(),
              _legendDot(null, 'Income'),
              const SizedBox(width: 16),
              _legendDot(WebTheme.tan, 'Expense'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i != 0) const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _GrowBar(
                                delay: Duration(milliseconds: 70 * i),
                                heightFraction:
                                    (income[i] / maxV).clamp(0.03, 1.0),
                                maxHeight: 118,
                                width: 22,
                                decoration: const BoxDecoration(
                                  gradient: WebTheme.barGradient,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(2)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              _GrowBar(
                                delay: Duration(
                                    milliseconds: 70 * i + 40),
                                heightFraction:
                                    (expense[i] / maxV).clamp(0.03, 1.0),
                                maxHeight: 118,
                                width: 22,
                                decoration: const BoxDecoration(
                                  color: WebTheme.tan,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM')
                              .format(months[i])
                              .toUpperCase(),
                          style: WebTheme.label(
                              size: 9,
                              color: WebTheme.inkMuted,
                              tracking: 0.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color? color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            gradient: color == null ? WebTheme.barGradient : null,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: WebTheme.bodyStyle(size: 11, color: WebTheme.inkSoft)),
      ],
    );
  }
}

/// Client dues with orange→gold paid-progress bars.
class _ClientDuesCard extends StatelessWidget {
  const _ClientDuesCard({required this.dues});
  final List<DueEntry> dues;

  static const _avatarTints = [
    (WebTheme.orangeTint, WebTheme.orangeDeep),
    (WebTheme.nightTint, WebTheme.nightText),
    (WebTheme.amberTint, WebTheme.amberText),
    (WebTheme.successTint, WebTheme.success),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = [...dues]..sort((a, b) => b.due.compareTo(a.due));
    final shown = sorted.take(6).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Client Dues', style: WebTheme.displayStyle(size: 16)),
              const Spacer(),
              _PillButton(
                label: 'SEND REMINDERS',
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteNames.reminders),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('No outstanding dues 🎉',
                  textAlign: TextAlign.center,
                  style: WebTheme.bodyStyle(
                      size: 12.5, color: WebTheme.inkMuted)),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i != 0) const SizedBox(height: 10),
              WebEntrance(
                delay: Duration(milliseconds: 50 * i),
                offset: 6,
                child: _dueRow(context, shown[i], i),
              ),
            ],
        ],
      ),
    );
  }

  Widget _dueRow(BuildContext context, DueEntry d, int i) {
    final name =
        d.clientName?.isNotEmpty == true ? d.clientName! : d.title;
    final tint = _avatarTints[i % _avatarTints.length];
    final pct = d.total <= 0 ? 0 : ((d.paid / d.total) * 100).round();

    return WebHoverHighlight(
      onTap: () => Navigator.of(context)
          .pushNamed(RouteNames.bookingDetail, arguments: d.bookingId),
      borderRadius: WebTheme.rRow,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orangeTint : WebTheme.pageBg,
          borderRadius: BorderRadius.circular(WebTheme.rRow),
          border: Border.all(
              color: hovering ? WebTheme.orange : WebTheme.innerLine),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.$1,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: WebTheme.bodyStyle(
                      size: 13,
                      weight: FontWeight.w700,
                      color: tint.$2),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(
                          size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${d.title} · ${DateFormat('d MMM').format(d.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 11, color: WebTheme.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Container(color: WebTheme.innerLine),
                          FractionallySizedBox(
                            widthFactor: (pct / 100).clamp(0.0, 1.0),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: WebTheme.sunsetWide),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pct% PAID OF ${_money(d.total)}',
                    style: WebTheme.label(
                        size: 9, color: WebTheme.inkMuted, tracking: 0.05),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              _money(d.due),
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: WebTheme.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════ TAB 2 EXPENSES
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  static String _emoji(String category) {
    final c = category.toLowerCase();
    if (c.contains('travel') || c.contains('transport')) return '🚐';
    if (c.contains('print') || c.contains('album')) return '🖨';
    if (c.contains('equip') || c.contains('gear') || c.contains('rent')) {
      return '💡';
    }
    if (c.contains('food')) return '🍱';
    if (c.contains('salary')) return '👥';
    if (c.contains('software')) return '💻';
    return '🧾';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseListControllerProvider);
    final expenses = async.valueOrNull ?? const <Expense>[];

    final now = DateTime.now();
    final thisMonth = expenses
        .where((e) =>
            e.incurredAt.year == now.year && e.incurredAt.month == now.month)
        .toList()
      ..sort((a, b) => b.incurredAt.compareTo(a.incurredAt));
    final total =
        thisMonth.fold<double>(0, (s, e) => s + e.amount);
    final eventLinked = thisMonth
        .where((e) => e.eventId != null)
        .fold<double>(0, (s, e) => s + e.amount);
    final general = total - eventLinked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebEntrance(
          delay: const Duration(milliseconds: 50),
          child: Row(
            children: [
              Expanded(
                  child: _summaryTile('THIS MONTH', _money(total),
                      WebTheme.ink, WebTheme.inkMuted)),
              const SizedBox(width: 14),
              Expanded(
                  child: _summaryTile('EVENT-LINKED', _money(eventLinked),
                      WebTheme.orange, WebTheme.orangeDeep)),
              const SizedBox(width: 14),
              Expanded(
                  child: _summaryTile('GENERAL', _money(general),
                      WebTheme.inkSoft, WebTheme.inkMuted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WebEntrance(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
            decoration: BoxDecoration(
              color: WebTheme.surface,
              borderRadius: BorderRadius.circular(WebTheme.rCard),
              border: Border.all(color: WebTheme.hairline),
              boxShadow: WebTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                        'Expenses · ${DateFormat('MMMM').format(now)}',
                        style: WebTheme.displayStyle(size: 16)),
                    const Spacer(),
                    _PillButton(
                      label: '+ ADD EXPENSE',
                      onTap: () => AddExpenseSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (async.isLoading && expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(children: [
                      WebShimmer(height: 52, borderRadius: 14),
                      SizedBox(height: 9),
                      WebShimmer(height: 52, borderRadius: 14),
                    ]),
                  )
                else if (thisMonth.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('No expenses logged this month.',
                        textAlign: TextAlign.center,
                        style: WebTheme.bodyStyle(
                            size: 12.5, color: WebTheme.inkMuted)),
                  )
                else
                  for (var i = 0; i < thisMonth.length; i++) ...[
                    if (i != 0) const SizedBox(height: 9),
                    WebEntrance(
                      delay:
                          Duration(milliseconds: (45 * i).clamp(0, 400)),
                      offset: 6,
                      child: _expenseRow(thisMonth[i]),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(
      String label, String value, Color valueColor, Color labelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rTile),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: WebTheme.label(
                  size: 9, color: labelColor, tracking: 0.15)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: WebTheme.displayStyle(
                    size: 26, weight: FontWeight.w800, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _expenseRow(Expense e) {
    final linked = e.eventId != null;
    final title =
        (e.note?.trim().isNotEmpty ?? false) ? e.note!.trim() : e.category;
    final dateLine = DateFormat('d MMM yyyy').format(e.incurredAt) +
        (e.receiptUrl != null ? ' · 📎 receipt' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.pageBg,
        borderRadius: BorderRadius.circular(WebTheme.rRow),
        border: Border.all(color: WebTheme.innerLine),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: linked ? WebTheme.orangeTint : WebTheme.amberTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(_emoji(e.category),
                    style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(dateLine,
                    style: WebTheme.bodyStyle(
                        size: 10.5, color: WebTheme.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: linked ? WebTheme.orangeTint : WebTheme.pageBgDeep,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
              border: Border.all(
                  color: linked
                      ? WebTheme.orangeTintBorder
                      : WebTheme.hairline),
            ),
            child: Text(
              e.category.toUpperCase(),
              style: WebTheme.label(
                size: 9,
                tracking: 0.08,
                color:
                    linked ? WebTheme.orangeDeep : WebTheme.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '− ${_money(e.amount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: WebTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════ TAB 3 CASH FLOW
class _CashFlowTab extends ConsumerWidget {
  const _CashFlowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref
            .watch(bookingListAllProvider(const BookingFilter()))
            .valueOrNull ??
        const <Booking>[];
    final expenses =
        ref.watch(expenseListControllerProvider).valueOrNull ??
            const <Expense>[];
    final petty =
        ref.watch(pettyCashListProvider).valueOrNull ??
            const <PettyCashEntry>[];
    final cashFlowPackages = ref.watch(packagesProvider).valueOrNull ??
        const <booking_pkg.Package>[];
    final cashFlowPackageById = _packageLookup(cashFlowPackages);

    final now = DateTime.now();
    // Projected expense = average of the last 3 months (incl. petty cash).
    double monthExpense(DateTime m) =>
        expenses
            .where((e) =>
                e.incurredAt.year == m.year &&
                e.incurredAt.month == m.month)
            .fold<double>(0, (s, e) => s + e.amount) +
        petty
            .where(
                (p) => p.date.year == m.year && p.date.month == m.month)
            .fold<double>(0, (s, p) => s + p.amount);
    final histAvg = List.generate(
            3, (i) => monthExpense(DateTime(now.year, now.month - i)))
        .fold<double>(0, (s, v) => s + v) /
        3;

    final months =
        List.generate(3, (i) => DateTime(now.year, now.month + 1 + i, 1));
    final rows = months.map((m) {
      double confirmed = 0;
      double pending = 0;
      for (final b in bookings) {
        if (b.date.year != m.year || b.date.month != m.month) continue;
        final price = _bookingTotal(b, cashFlowPackageById);
        switch (b.status) {
          case BookingStatus.confirmed:
          case BookingStatus.inProgress:
          case BookingStatus.shotComplete:
          case BookingStatus.completed:
          case BookingStatus.delivered:
            confirmed += price;
          case BookingStatus.pending:
            pending += price;
          case BookingStatus.cancelled:
            break;
        }
      }
      return (
        label: DateFormat('MMM').format(m).toUpperCase(),
        confirmed: confirmed,
        pending: pending,
        expense: histAvg,
      );
    }).toList();

    final maxV = rows.fold<double>(
        1,
        (mx, r) => [r.confirmed, r.pending, r.expense]
            .fold<double>(mx, (m2, v) => v > m2 ? v : m2));

    return WebEntrance(
      delay: const Duration(milliseconds: 50),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Cash Flow · next 3 months',
                    style: WebTheme.displayStyle(size: 16)),
                const Spacer(),
                _GhostChip(
                  label: 'PDF ↓',
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.reports),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _legend(
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: WebTheme.barGradient)),
                    'Confirmed income'),
                _legend(
                    CustomPaint(painter: _HatchPainter()), 'Pending'),
                _legend(
                    const ColoredBox(color: WebTheme.tan),
                    'Expense (projected)'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i != 0) const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                _GrowBar(
                                  delay:
                                      Duration(milliseconds: 80 * i),
                                  heightFraction: (rows[i].confirmed /
                                          maxV)
                                      .clamp(0.03, 1.0),
                                  maxHeight: 140,
                                  width: 34,
                                  decoration: const BoxDecoration(
                                    gradient: WebTheme.barGradient,
                                    borderRadius:
                                        BorderRadius.vertical(
                                            top: Radius.circular(8),
                                            bottom:
                                                Radius.circular(2)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _GrowBar(
                                  delay: Duration(
                                      milliseconds: 80 * i + 50),
                                  heightFraction:
                                      (rows[i].pending / maxV)
                                          .clamp(0.03, 1.0),
                                  maxHeight: 140,
                                  width: 34,
                                  hatched: true,
                                ),
                                const SizedBox(width: 8),
                                _GrowBar(
                                  delay: Duration(
                                      milliseconds: 80 * i + 100),
                                  heightFraction:
                                      (rows[i].expense / maxV)
                                          .clamp(0.03, 1.0),
                                  maxHeight: 140,
                                  width: 34,
                                  decoration: const BoxDecoration(
                                    color: WebTheme.tan,
                                    borderRadius:
                                        BorderRadius.vertical(
                                            top: Radius.circular(8),
                                            bottom:
                                                Radius.circular(2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(rows[i].label,
                              style: WebTheme.label(
                                  size: 10,
                                  color: WebTheme.ink,
                                  tracking: 0.12,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${_moneyCompact(rows[i].confirmed + rows[i].pending)} proj.',
                            style: WebTheme.label(
                                size: 9,
                                color: WebTheme.inkMuted,
                                tracking: 0.05),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Widget swatch, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(3), child: swatch),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: WebTheme.bodyStyle(size: 11, color: WebTheme.inkSoft)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════ TAB 4 PETTY CASH
class _PettyTab extends ConsumerWidget {
  const _PettyTab();

  static (Color, Color, Color) _catColors(PettyCashCategory c) {
    switch (c) {
      case PettyCashCategory.transport:
        return (
          WebTheme.orangeTint,
          WebTheme.orangeTintBorder,
          WebTheme.orangeDeep
        );
      case PettyCashCategory.food:
        return (
          WebTheme.successTint,
          WebTheme.successTintBorder,
          WebTheme.success
        );
      case PettyCashCategory.print:
        return (
          WebTheme.nightTint,
          WebTheme.nightTintBorder,
          WebTheme.nightText
        );
      case PettyCashCategory.phone:
        return (
          WebTheme.amberTint,
          WebTheme.amberTintBorder,
          WebTheme.amberText
        );
      case PettyCashCategory.misc:
        return (WebTheme.pageBgDeep, WebTheme.hairline, WebTheme.inkMuted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(pettyCashListProvider).valueOrNull ??
            const <PettyCashEntry>[];
    final balance = ref.watch(pettyCashBalanceProvider);

    final now = DateTime.now();
    final monthSpend = entries
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);

    // Newest first with a running balance column.
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final running = <String, double>{};
    var acc = 0.0;
    for (final e in sorted) {
      acc += e.amount;
      running[e.id] = acc;
    }
    final display = sorted.reversed.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebEntrance(
          delay: const Duration(milliseconds: 50),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: WebTheme.chrome,
                    borderRadius: BorderRadius.circular(WebTheme.rTile),
                    boxShadow: WebTheme.darkCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'SPENT · ${DateFormat('MMMM').format(now).toUpperCase()}',
                          style: WebTheme.label(
                              size: 9,
                              color: WebTheme.amber,
                              tracking: 0.15)),
                      const SizedBox(height: 4),
                      Text(_money(monthSpend),
                          style: WebTheme.displayStyle(
                              size: 26,
                              weight: FontWeight.w800,
                              color: WebTheme.chromeInk)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: WebTheme.surface,
                    borderRadius: BorderRadius.circular(WebTheme.rTile),
                    border: Border.all(color: WebTheme.hairline),
                    boxShadow: WebTheme.cardShadowSmall,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('TOTAL BOOK',
                          style: WebTheme.label(
                              size: 9,
                              color: WebTheme.inkMuted,
                              tracking: 0.15)),
                      const SizedBox(height: 4),
                      Text(_money(balance),
                          style: WebTheme.displayStyle(
                              size: 26,
                              weight: FontWeight.w800,
                              color: WebTheme.success)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PillButton(
                    label: '+ ENTRY',
                    onTap: () => _showAddEntry(context, ref),
                  ),
                  const SizedBox(height: 8),
                  _GhostChip(
                    label: 'PDF ↓',
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.reports),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WebEntrance(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
            decoration: BoxDecoration(
              color: WebTheme.surface,
              borderRadius: BorderRadius.circular(WebTheme.rCard),
              border: Border.all(color: WebTheme.hairline),
              boxShadow: WebTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (display.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('No petty cash entries yet.',
                        textAlign: TextAlign.center,
                        style: WebTheme.bodyStyle(
                            size: 12.5, color: WebTheme.inkMuted)),
                  )
                else
                  for (var i = 0; i < display.length; i++) ...[
                    if (i != 0) const SizedBox(height: 9),
                    WebEntrance(
                      delay:
                          Duration(milliseconds: (45 * i).clamp(0, 400)),
                      offset: 6,
                      child: _entryRow(
                          display[i], running[display[i].id] ?? 0),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryRow(PettyCashEntry e, double runningBalance) {
    final colors = _catColors(e.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.pageBg,
        borderRadius: BorderRadius.circular(WebTheme.rRow),
        border: Border.all(color: WebTheme.innerLine),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
              border: Border.all(color: colors.$2),
            ),
            child: Center(
              child: Text(
                e.category.name.toUpperCase(),
                style: WebTheme.label(
                    size: 9, color: colors.$3, tracking: 0.08),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(DateFormat('d MMM yyyy').format(e.date),
                    style: WebTheme.bodyStyle(
                        size: 10.5, color: WebTheme.inkMuted)),
              ],
            ),
          ),
          Text(
            '− ${_money(e.amount)}',
            style: TextStyle(
              fontFamily: WebTheme.mono,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: WebTheme.danger,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              _money(runningBalance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 10,
                color: WebTheme.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web add-entry dialog — same fields/validation as the mobile sheet,
  /// writing through the same notifier.
  void _showAddEntry(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var category = PettyCashCategory.misc;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: WebTheme.surface,
          title: Text('New petty cash entry',
              style: WebTheme.displayStyle(size: 17)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: 'Amount'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in PettyCashCategory.values)
                        ChoiceChip(
                          label: Text(c.name[0].toUpperCase() +
                              c.name.substring(1)),
                          selected: category == c,
                          onSelected: (_) =>
                              setDialogState(() => category = c),
                          selectedColor: WebTheme.orange,
                          labelStyle: TextStyle(
                            color: category == c
                                ? Colors.white
                                : WebTheme.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: WebTheme.orange),
              onPressed: () {
                final title = titleCtrl.text.trim();
                final amount =
                    double.tryParse(amountCtrl.text.trim());
                if (title.isEmpty || amount == null || amount <= 0) {
                  return;
                }
                ref.read(pettyCashListProvider.notifier).add(
                      PettyCashEntry(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        title: title,
                        category: category,
                        amount: amount,
                        date: DateTime.now(),
                      ),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      amountCtrl.dispose();
    });
  }
}

// ═══════════════════════════════════════════════════════ TAB 5 SALARY
class _SalaryTab extends ConsumerWidget {
  const _SalaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffPayoutsProvider);
    final sheet = async.valueOrNull;
    final members = sheet?.members ?? const <StaffPayout>[];

    return WebEntrance(
      delay: const Duration(milliseconds: 50),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                    'Salary Sheet · ${DateFormat('MMMM').format(DateTime.now())}',
                    style: WebTheme.displayStyle(size: 16)),
                const Spacer(),
                _GhostChip(
                  label: 'PDF ↓',
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.reports),
                ),
                const SizedBox(width: 8),
                _GreenPill(
                  label: 'MARK ALL PAID',
                  onTap: members.any((m) => !m.isFullyPaid)
                      ? () => _payAll(context, ref, members)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (async.isLoading && members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Column(children: [
                  WebShimmer(height: 52, borderRadius: 14),
                  SizedBox(height: 8),
                  WebShimmer(height: 52, borderRadius: 14),
                ]),
              )
            else if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text('No team payouts recorded yet.',
                    textAlign: TextAlign.center,
                    style: WebTheme.bodyStyle(
                        size: 12.5, color: WebTheme.inkMuted)),
              )
            else ...[
              // Column headers.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(flex: 14, child: _colLabel('MEMBER')),
                    SizedBox(
                        width: 70,
                        child: _colLabel('EVENTS',
                            align: TextAlign.center)),
                    SizedBox(
                        width: 90,
                        child:
                            _colLabel('RATE', align: TextAlign.right)),
                    SizedBox(
                        width: 100,
                        child: _colLabel('EARNED',
                            align: TextAlign.right)),
                    SizedBox(
                        width: 100,
                        child:
                            _colLabel('PAID', align: TextAlign.right)),
                    SizedBox(
                        width: 100,
                        child: _colLabel('DUE', align: TextAlign.right)),
                    const SizedBox(width: 10),
                    const SizedBox(width: 90),
                  ],
                ),
              ),
              for (var i = 0; i < members.length; i++) ...[
                if (i != 0) const SizedBox(height: 8),
                WebEntrance(
                  delay: Duration(milliseconds: (45 * i).clamp(0, 400)),
                  offset: 6,
                  child: _memberRow(context, ref, members[i], i),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _colLabel(String text, {TextAlign align = TextAlign.left}) {
    return Text(text,
        textAlign: align,
        style: WebTheme.label(
            size: 8.5, color: WebTheme.inkMuted, tracking: 0.12));
  }

  static const _avatarTints = [
    (WebTheme.orangeTint, WebTheme.orangeDeep),
    (WebTheme.nightTint, WebTheme.nightText),
    (WebTheme.successTint, WebTheme.success),
    (WebTheme.amberTint, WebTheme.amberText),
  ];

  Widget _memberRow(
      BuildContext context, WidgetRef ref, StaffPayout m, int i) {
    final settled = m.isFullyPaid;
    final rate = m.events > 0 ? m.earned / m.events : 0.0;
    final tint = _avatarTints[i % _avatarTints.length];

    String mono(num v) => _money(v);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.pageBg,
        borderRadius: BorderRadius.circular(WebTheme.rRow),
        border: Border.all(color: WebTheme.innerLine),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: tint.$1, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                      style: WebTheme.bodyStyle(
                          size: 12,
                          weight: FontWeight.w700,
                          color: tint.$2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(
                          size: 13, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text('${m.events}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: WebTheme.mono, fontSize: 12)),
          ),
          SizedBox(
            width: 90,
            child: Text(mono(rate),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: WebTheme.mono,
                    fontSize: 12,
                    color: WebTheme.inkSoft)),
          ),
          SizedBox(
            width: 100,
            child: Text(mono(m.earned),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: WebTheme.mono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 100,
            child: Text(mono(m.paid),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: WebTheme.mono,
                    fontSize: 12,
                    color: WebTheme.success)),
          ),
          SizedBox(
            width: 100,
            child: Text(mono(m.due),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: settled ? WebTheme.success : WebTheme.danger,
                )),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: settled
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: WebTheme.successTint,
                      borderRadius:
                          BorderRadius.circular(WebTheme.rFull),
                      border: Border.all(
                          color: WebTheme.successTintBorder),
                    ),
                    child: Center(
                      child: Text('PAID ✓',
                          style: WebTheme.label(
                              size: 8.5,
                              color: WebTheme.success,
                              tracking: 0.08)),
                    ),
                  )
                : WebHoverHighlight(
                    onTap: () => _payOne(context, ref, m),
                    borderRadius: WebTheme.rFull,
                    builder: (context, hovering) => AnimatedContainer(
                      duration: WebTheme.fast,
                      padding:
                          const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: hovering
                            ? WebTheme.orangeDark
                            : WebTheme.orange,
                        borderRadius:
                            BorderRadius.circular(WebTheme.rFull),
                      ),
                      child: Center(
                        child: Text('PAY',
                            style: WebTheme.label(
                                size: 8.5,
                                color: WebTheme.chromeInk,
                                tracking: 0.08)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _payOne(
      BuildContext context, WidgetRef ref, StaffPayout m) async {
    final ok = await _confirm(
      context,
      title: 'Pay ${m.name}?',
      message:
          'Mark this member\'s ${m.events} ${m.events == 1 ? 'event' : 'events'} as paid.',
    );
    if (ok) {
      await ref
          .read(teamControllerProvider.notifier)
          .markPayoutPaid(m.userId);
    }
  }

  Future<void> _payAll(BuildContext context, WidgetRef ref,
      List<StaffPayout> members) async {
    final unpaid = members.where((m) => !m.isFullyPaid).toList();
    if (unpaid.isEmpty) return;
    final ok = await _confirm(
      context,
      title: 'Pay all members?',
      message:
          'Settle every outstanding payout for ${unpaid.length} ${unpaid.length == 1 ? 'member' : 'members'}.',
    );
    if (!ok) return;
    for (final m in unpaid) {
      await ref
          .read(teamControllerProvider.notifier)
          .markPayoutPaid(m.userId);
    }
  }

  Future<bool> _confirm(BuildContext context,
      {required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WebTheme.surface,
        title: Text(title, style: WebTheme.displayStyle(size: 17)),
        content: Text(message,
            style: WebTheme.bodyStyle(size: 13, color: WebTheme.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WebTheme.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ═══════════════════════════════════════════════════════ TAB 6 PAYOUTS
/// Reuses the existing web payout board (approve/settle payout requests) —
/// it reads the same staffPayoutsProvider and wears the Sunset tokens.
class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WebPayouts(
      onPay: (m) async {
        await ref
            .read(teamControllerProvider.notifier)
            .markPayoutPaid(m.userId);
      },
      onPayAll: () async {
        final sheet = ref.read(staffPayoutsProvider).valueOrNull;
        if (sheet == null) return;
        for (final m in sheet.members.where((m) => !m.isFullyPaid)) {
          await ref
              .read(teamControllerProvider.notifier)
              .markPayoutPaid(m.userId);
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════ SHARED PIECES
/// Orange mono pill (SEND REMINDERS / + ADD EXPENSE / + ENTRY).
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orangeDark : WebTheme.orange,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          boxShadow: WebTheme.buttonGlow,
        ),
        child: Text(label,
            style: WebTheme.label(
                size: 9,
                color: WebTheme.chromeInk,
                tracking: 0.1,
                weight: FontWeight.w700)),
      ),
    );
  }
}

/// Orange-tint ghost chip (PDF ↓) — fills orange on hover.
class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orange : WebTheme.orangeTint,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
              color: hovering ? WebTheme.orange : WebTheme.orangeTintBorder),
        ),
        child: Text(label,
            style: WebTheme.label(
              size: 9,
              tracking: 0.1,
              color: hovering ? WebTheme.chromeInk : WebTheme.orangeDeep,
            )),
      ),
    );
  }
}

/// Green pill (MARK ALL PAID); disabled = faded.
class _GreenPill extends StatelessWidget {
  const _GreenPill({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? WebTheme.successTint
              : hovering
                  ? const Color(0xFF177E54)
                  : WebTheme.success,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
        ),
        child: Text(label,
            style: WebTheme.label(
              size: 9,
              tracking: 0.1,
              color: enabled ? Colors.white : WebTheme.success,
              weight: FontWeight.w700,
            )),
      ),
    );
  }
}

/// Hover lift by −3px, reduce-motion aware.
class _HoverLiftBox extends StatefulWidget {
  const _HoverLiftBox({required this.child});
  final Widget child;

  @override
  State<_HoverLiftBox> createState() => _HoverLiftBoxState();
}

class _HoverLiftBoxState extends State<_HoverLiftBox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: noMotion ? Duration.zero : WebTheme.base,
        curve: WebTheme.ease,
        transform: Matrix4.translationValues(
            0, _hover && !noMotion ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// Bottom-anchored growing bar (`barGrow`), fixed width, optional hatching.
class _GrowBar extends StatefulWidget {
  const _GrowBar({
    required this.heightFraction,
    required this.maxHeight,
    required this.width,
    this.decoration,
    this.hatched = false,
    this.delay = Duration.zero,
  });

  final double heightFraction;
  final double maxHeight;
  final double width;
  final BoxDecoration? decoration;
  final bool hatched;
  final Duration delay;

  @override
  State<_GrowBar> createState() => _GrowBarState();
}

class _GrowBarState extends State<_GrowBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (noMotion) {
      _c.value = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = CurvedAnimation(parent: _c, curve: WebTheme.ease).value;
        final h = widget.maxHeight * widget.heightFraction * t;
        if (widget.hatched) {
          return Container(
            width: widget.width,
            height: h,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8), bottom: Radius.circular(2)),
              border: Border.all(
                  color: WebTheme.orange.withValues(alpha: 0.55),
                  width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7), bottom: Radius.circular(1)),
              child: CustomPaint(
                  painter: _HatchPainter(), size: Size.infinite),
            ),
          );
        }
        return Container(
          width: widget.width,
          height: h,
          decoration: widget.decoration,
        );
      },
    );
  }
}

/// 45° repeating orange stripes on a faint orange wash (handoff "pending").
class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = WebTheme.orange.withValues(alpha: 0.08);
    canvas.drawRect(Offset.zero & size, bg);
    final stripe = Paint()
      ..color = WebTheme.orange.withValues(alpha: 0.4)
      ..strokeWidth = 3;
    for (double x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────────────────────────────────────────── HELPERS
Map<String, booking_pkg.Package> _packageLookup(
  List<booking_pkg.Package> packages,
) {
  return <String, booking_pkg.Package>{
    for (final p in packages) p.id: p,
    for (final p in packages)
      if (p.remoteId != null) p.remoteId!: p,
  };
}

double _bookingTotal(
  Booking booking,
  Map<String, booking_pkg.Package> packageById,
) {
  final custom = booking.customPrice;
  if (custom != null && custom > 0) return custom;
  final packageId = booking.packageId;
  if (packageId == null || packageId.isEmpty) return 0;
  final package = packageById[packageId];
  return package == null ? 0 : package.netPrice;
}

final NumberFormat _moneyFmt = NumberFormat.decimalPattern('en');

/// "৳ 2,84,500"-style with the active currency symbol.
String _money(num v) => ActiveCurrency.value.wrap(_moneyFmt.format(v.round()));

/// Compact "৳ 1.1L"-style for chart captions.
String _moneyCompact(num v) {
  final n = v.abs();
  String body;
  if (n >= 10000000) {
    body = '${(v / 10000000).toStringAsFixed(1)}Cr';
  } else if (n >= 100000) {
    body = '${(v / 100000).toStringAsFixed(1)}L';
  } else if (n >= 1000) {
    body = '${(v / 1000).toStringAsFixed(1)}K';
  } else {
    body = v.round().toString();
  }
  return ActiveCurrency.value.wrap(body);
}
