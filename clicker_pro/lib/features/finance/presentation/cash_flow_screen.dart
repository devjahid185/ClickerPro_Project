import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/currency.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../expenses/application/expense_providers.dart';
import '../../petty_cash/domain/petty_cash_entry.dart';
import '../../petty_cash/presentation/petty_cash_screen.dart';
import '../../../theme/app_theme.dart';

/// Active-currency money with South-Asian grouping — "৳1,86,500" / "$1,86,500".
String _money(double v) =>
    ActiveCurrency.value.wrap(NumberFormat('#,##,##0', 'en_IN').format(v.round()));

/// One month's cash-flow figures derived from real booking data.
class _MonthFlow {
  const _MonthFlow(
    this.month,
    this.solid,
    this.hatched,
    this.pending,
    this.pettyCashOut,
  );
  final String month;
  final double solid;   // completed / delivered bookings
  final double hatched; // confirmed / inProgress
  final double pending; // pending bookings
  final double pettyCashOut; // petty cash spent this month (cash out)
  double get total => solid + hatched + pending;
}

/// Derives the last 6 months of cash-flow from the live booking stream,
/// overlaying petty-cash spending so added cash is visible on the timeline.
final _cashFlowProvider = StreamProvider<List<_MonthFlow>>((ref) {
  final bookingsAsync = ref.watch(bookingListAllProvider(const BookingFilter()));
  final pettyCash =
      ref.watch(pettyCashListProvider).valueOrNull ??
      const <PettyCashEntry>[];
  return bookingsAsync.when(
    loading: () => Stream.value(<_MonthFlow>[]),
    error: (_, _) => Stream.value(<_MonthFlow>[]),
    data: (bookings) {
      const mNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final now = DateTime.now();
      // Build last 6 months (oldest first)
      final months = List.generate(6, (i) {
        return DateTime(now.year, now.month - 5 + i, 1);
      });
      final flows = months.map((m) {
        final label = '${mNames[m.month - 1]} ${m.year}';
        double solid = 0;
        double hatched = 0;
        double pending = 0;
        final pettyOut = pettyCash
            .where((p) => p.date.year == m.year && p.date.month == m.month)
            .fold<double>(0, (s, p) => s + p.amount);
        for (final b in bookings) {
          if (b.date.year != m.year || b.date.month != m.month) continue;
          final price = (b.customPrice ?? 0).toDouble();
          switch (b.status) {
            case BookingStatus.completed:
            case BookingStatus.delivered:
              solid += price;
            case BookingStatus.confirmed:
            case BookingStatus.inProgress:
              hatched += price;
            case BookingStatus.pending:
              pending += price;
            case BookingStatus.shotComplete:
              hatched += price;
            case BookingStatus.cancelled:
              break;
          }
        }
        return _MonthFlow(label, solid, hatched, pending, pettyOut);
      }).toList();
      return Stream.value(flows);
    },
  );
});

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cashFlowProvider);
    // On wide web the content panel is very wide; cap + centre so the cards
    // read as a column rather than stretching edge-to-edge. Mobile unchanged.
    final capWidth = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: kIsWeb ? Colors.transparent : AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Cash Flow',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.filmDim,
            ),
            onPressed: () {
              final months = async.valueOrNull ?? [];
              if (months.isNotEmpty) _exportPdf(context, months);
            },
          ),
        ],
      ),
      body: _CapWidth(
        cap: capWidth,
        child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: Icons.bar_chart_outlined,
            message: 'Could not load cash flow data.',
          ),
        ),
        data: (months) {
          final nonEmpty = months
              .where((m) => m.total > 0 || m.pettyCashOut > 0)
              .toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              _buildProfitSummary(ref),
              const SizedBox(height: 22),
              _SectionHeader('LAST 6 MONTHS'),
              const SizedBox(height: 14),
              if (nonEmpty.isEmpty) ...[
                const SizedBox(height: 60),
                const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  message: 'No booking revenue yet.\nAdd bookings to see cash flow.',
                ),
              ] else ...[
                for (final m in months) ...[
                  _buildMonthCard(m),
                  const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 10),
              _buildLegend(),
            ],
          );
        },
      ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<_MonthFlow> months) async {
    final messenger = ScaffoldMessenger.of(context);
    final grandTotal = months.fold<double>(0, (s, m) => s + m.total);
    String f(double v) => _money(v);
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Cash Flow Timeline',
          fileName: 'cash_flow_timeline',
          subtitle: '6-month overview',
          summary: [
            PdfRow('Total revenue', f(grandTotal), emphasize: true),
          ],
          table: PdfTable(
            headers: const ['Month', 'Confirmed', 'Tentative', 'Pending', 'Total'],
            rows: [
              for (final m in months)
                [m.month, f(m.solid), f(m.hatched), f(m.pending), f(m.total)],
            ],
          ),
          footnote: 'Generated by Graphy7',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create PDF: $e')),
      );
    }
  }

  /// Real income / expense / net-profit hero from the live profit-loss API.
  /// Petty cash counts as expense (per product decision), so it is folded
  /// into the Expenses figure and subtracted from Net Profit here.
  Widget _buildProfitSummary(WidgetRef ref) {
    final async = ref.watch(profitLossProvider);
    final pettyTotal = (ref.watch(pettyCashListProvider).valueOrNull ??
            const <PettyCashEntry>[])
        .fold<double>(0, (s, p) => s + p.amount);
    return async.when(
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: LensLoader()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (pl) {
        final totalExpense = pl.totalExpense + pettyTotal;
        final netProfit = pl.totalIncome - totalExpense;
        return _NetHero(
          net: netProfit,
          income: pl.totalIncome,
          expense: totalExpense,
        );
      },
    );
  }

  Widget _buildMonthCard(_MonthFlow m) {
    final total = m.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                m.month,
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _money(total),
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBar(m.solid, m.hatched, m.pending, total),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStat('Confirmed', m.solid, AppColors.orange),
              const SizedBox(width: 16),
              _buildStat('Tentative', m.hatched, AppColors.gold),
              const SizedBox(width: 16),
              _buildStat('Pending', m.pending, AppColors.filmMuted),
            ],
          ),
          if (m.pettyCashOut > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.line(0.06)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.savings_outlined, color: AppColors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Petty Cash Out',
                  style: TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '− ${_money(m.pettyCashOut)}',
                  style: TextStyle(
                    color: AppColors.red,
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBar(double solid, double hatched, double pending, double total) {
    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Text(
          'No bookings this month',
          style: TextStyle(color: AppColors.filmMuted, fontSize: 9),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (solid > 0)
              Expanded(
                flex: (solid / total * 1000).toInt(),
                child: Container(color: AppColors.orange),
              ),
            if (hatched > 0) ...[
              const SizedBox(width: 2),
              Expanded(
                flex: (hatched / total * 1000).toInt(),
                child: Container(color: AppColors.gold),
              ),
            ],
            if (pending > 0) ...[
              const SizedBox(width: 2),
              Expanded(
                flex: (pending / total * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.filmMuted.withValues(alpha: 0.28),
                  ),
                  child: CustomPaint(painter: _HatchPainter()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.filmMuted,
                fontFamily: AppText.monoFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _money(value),
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              color: AppColors.filmMuted,
              fontFamily: AppText.monoFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.16,
            ),
          ),
          const SizedBox(height: 10),
          _legendItem(AppColors.orange, 'Confirmed — Delivered / Completed'),
          _legendItem(AppColors.gold, 'Tentative — Confirmed / In Progress'),
          _legendItem(AppColors.filmMuted, 'Pending — Awaiting confirmation'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Solid-orange hero card: NET PROFIT figure + income/expense inline stat row.
/// Mirrors the Finance / Freelancer Payout hero pattern (.dc.html).
class _NetHero extends StatelessWidget {
  const _NetHero({
    required this.net,
    required this.income,
    required this.expense,
  });

  final double net;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Corner-glow circle bleeding off the top-right.
            Positioned(
              right: -60,
              top: -55,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Soft radial bleed instead of a hard-edged ring.
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET PROFIT · THIS MONTH',
                    style: TextStyle(
                      color: AppColors.onAccent.withValues(alpha: 0.85),
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _money(net),
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.03,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroStat('INCOME', income),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _heroStat('EXPENSE', expense),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.onAccent.withValues(alpha: 0.75),
            fontFamily: AppText.monoFontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.14,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _money(value),
          style: TextStyle(
            color: AppColors.onAccent,
            fontFamily: AppText.brandFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Mono uppercase micro-label with the signature orange 26×1.5px rule.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 1.5,
          color: AppColors.orange,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmMuted,
            fontFamily: AppText.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.16,
          ),
        ),
      ],
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.filmMuted.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 4) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Centres and caps its child's width on wide web so finance cards read as a
/// column instead of stretching across the whole content panel. A no-op
/// (pass-through) when [cap] is false — i.e. on mobile / narrow web.
class _CapWidth extends StatelessWidget {
  const _CapWidth({required this.cap, required this.child});
  final bool cap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!cap) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}
