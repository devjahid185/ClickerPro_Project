import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../expenses/application/expense_providers.dart';

/// One month's cash-flow figures derived from real booking data.
class _MonthFlow {
  const _MonthFlow(this.month, this.solid, this.hatched, this.pending);
  final String month;
  final double solid;   // completed / delivered bookings
  final double hatched; // confirmed / inProgress
  final double pending; // pending bookings
  double get total => solid + hatched + pending;
}

/// Derives the last 6 months of cash-flow from the live booking stream.
final _cashFlowProvider = StreamProvider<List<_MonthFlow>>((ref) {
  final bookingsAsync = ref.watch(bookingListProvider(const BookingFilter()));
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
        return _MonthFlow(label, solid, hatched, pending);
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
          'Cash Flow Timeline',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.gold,
            ),
            onPressed: () {
              final months = async.valueOrNull ?? [];
              if (months.isNotEmpty) _exportPdf(context, months);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: Icons.bar_chart_outlined,
            message: 'Could not load cash flow data.',
          ),
        ),
        data: (months) {
          final nonEmpty = months.where((m) => m.total > 0).toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfitSummary(ref),
              const SizedBox(height: 16),
              if (nonEmpty.isEmpty) ...[
                const SizedBox(height: 80),
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
              const SizedBox(height: 12),
              _buildLegend(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<_MonthFlow> months) async {
    final messenger = ScaffoldMessenger.of(context);
    final grandTotal = months.fold<double>(0, (s, m) => s + m.total);
    String f(double v) => '৳ ${v.toStringAsFixed(0)}';
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
          footnote: 'Generated by Clicker Pro',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF তৈরি করা যায়নি: $e')),
      );
    }
  }

  /// Real income / expense / net-profit band from the live profit-loss API.
  Widget _buildProfitSummary(WidgetRef ref) {
    final async = ref.watch(profitLossProvider);
    return async.when(
      loading: () => Container(
        height: 96,
        decoration: AppColors.glassCardDecoration(),
        child: const Center(child: LensLoader()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (pl) {
        String f(double v) => '৳ ${v.toStringAsFixed(0)}';
        Widget cell(String label, double value, Color color) => Expanded(
          child: Column(
            children: [
              Text(
                f(value),
                style: TextStyle(
                  color: color,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.filmMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: AppColors.glassCardDecoration(),
          child: Row(
            children: [
              cell('Income', pl.totalIncome, AppColors.green),
              cell('Expenses', pl.totalExpense, AppColors.red),
              cell('Net Profit', pl.netProfit,
                  pl.netProfit >= 0 ? AppColors.orange : AppColors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthCard(_MonthFlow m) {
    final total = m.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.month,
            style: const TextStyle(
              color: AppColors.film,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildBar(m.solid, m.hatched, m.pending, total),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat('Confirmed', m.solid, AppColors.teal),
              const SizedBox(width: 16),
              _buildStat('Tentative', m.hatched, AppColors.gold),
              const SizedBox(width: 16),
              _buildStat('Pending', m.pending, AppColors.filmMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double solid, double hatched, double pending, double total) {
    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'No bookings this month',
            style: TextStyle(color: AppColors.filmMuted, fontSize: 9),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (solid > 0)
              Expanded(
                flex: (solid / total * 1000).toInt(),
                child: Container(color: AppColors.teal),
              ),
            if (hatched > 0) ...[
              const SizedBox(width: 1),
              Expanded(
                flex: (hatched / total * 1000).toInt(),
                child: Container(color: AppColors.gold),
              ),
            ],
            if (pending > 0) ...[
              const SizedBox(width: 1),
              Expanded(
                flex: (pending / total * 1000).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.filmMuted.withValues(alpha: 0.4),
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
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '৳ ${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              color: AppColors.film,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _legendItem(AppColors.teal, 'Confirmed — Delivered / Completed'),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.filmMuted.withValues(alpha: 0.3)
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
