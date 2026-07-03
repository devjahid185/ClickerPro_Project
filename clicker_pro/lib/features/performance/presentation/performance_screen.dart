// lib/features/performance/presentation/performance_screen.dart
//
// Studio performance analytics screen. Derives key metrics from the
// local booking list — total bookings, status breakdown, and event-type
// distribution. Works fully offline (local-first Drift data).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../../theme/app_theme.dart';

// ─── Derived metrics ─────────────────────────────────────────────────────────

class _StudioMetrics {
  _StudioMetrics({
    required this.total,
    required this.byStatus,
    required this.byMonth,
    required this.completionRate,
    required this.cancellationRate,
    required this.activeCount,
  });

  final int total;
  final Map<BookingStatus, int> byStatus;
  final Map<String, int> byMonth;
  final double completionRate;
  final double cancellationRate;
  final int activeCount;

  factory _StudioMetrics.from(List<Booking> bookings) {
    final byStatus = <BookingStatus, int>{};
    final byMonth = <String, int>{};

    for (final b in bookings) {
      byStatus[b.status] = (byStatus[b.status] ?? 0) + 1;
      final key =
          '${b.date.year}-${b.date.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + 1;
    }

    final total = bookings.length;
    final completed = byStatus[BookingStatus.completed] ?? 0;
    final cancelled = byStatus[BookingStatus.cancelled] ?? 0;
    final active = bookings
        .where((b) =>
            b.status != BookingStatus.completed &&
            b.status != BookingStatus.cancelled)
        .length;

    return _StudioMetrics(
      total: total,
      byStatus: byStatus,
      byMonth: byMonth,
      completionRate: total == 0 ? 0 : completed / total,
      cancellationRate: total == 0 ? 0 : cancelled / total,
      activeCount: active,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingListProvider(const BookingFilter()));

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
          'Performance',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => ErrorState(
          message: 'Failed to load performance data',
          onRetry: () => ref.invalidate(bookingListProvider),
        ),
        data: (bookings) {
          final metrics = _StudioMetrics.from(bookings);
          return _PerformanceBody(metrics: metrics);
        },
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody({required this.metrics});
  final _StudioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Top KPI row ──
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Bookings',
                value: '${metrics.total}',
                icon: Icons.event_note_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Active',
                value: '${metrics.activeCount}',
                icon: Icons.pending_actions_rounded,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Completion Rate',
                value: '${(metrics.completionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Cancellation Rate',
                value:
                    '${(metrics.cancellationRate * 100).toStringAsFixed(1)}%',
                icon: Icons.cancel_outlined,
                color: AppColors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Status breakdown ──
        _SectionTitle(title: 'Bookings by Status'),
        const SizedBox(height: 12),
        if (metrics.total == 0)
          _EmptyHint(message: 'No bookings recorded yet.')
        else
          _StatusBreakdown(byStatus: metrics.byStatus, total: metrics.total),
        const SizedBox(height: 24),

        // ── Monthly trend ──
        _SectionTitle(title: 'Monthly Trend'),
        const SizedBox(height: 12),
        if (metrics.byMonth.isEmpty)
          _EmptyHint(message: 'No data to display.')
        else
          _MonthlyChart(byMonth: metrics.byMonth),
      ],
    );
  }
}

// ─── KPI card ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status breakdown ────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({
    required this.byStatus,
    required this.total,
  });

  final Map<BookingStatus, int> byStatus;
  final int total;

  @override
  Widget build(BuildContext context) {
    final entries = BookingStatus.values
        .map((s) => MapEntry(s, byStatus[s] ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          for (final e in entries) ...[
            _StatusRow(status: e.key, count: e.value, total: total),
            if (e != entries.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final BookingStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final pct = total == 0 ? 0.0 : count / total;
    final label = status.name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)}',
        )
        .trim();

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
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label[0].toUpperCase() + label.substring(1),
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _colorFor(BookingStatus s) => switch (s) {
        BookingStatus.pending => AppColors.filmDim,
        BookingStatus.confirmed => AppColors.indigo,
        BookingStatus.inProgress => AppColors.orange,
        BookingStatus.shotComplete => AppColors.gold,
        BookingStatus.delivered => AppColors.teal,
        BookingStatus.completed => AppColors.green,
        BookingStatus.cancelled => AppColors.red,
      };
}

// ─── Monthly chart ───────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.byMonth});
  final Map<String, int> byMonth;

  @override
  Widget build(BuildContext context) {
    final sorted = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last12 = sorted.length > 12
        ? sorted.sublist(sorted.length - 12)
        : sorted;
    final maxCount = last12.fold(0, (m, e) => e.value > m ? e.value : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in last12) ...[
                  Expanded(
                    child: _Bar(
                      count: e.value,
                      maxCount: maxCount == 0 ? 1 : maxCount,
                    ),
                  ),
                  if (e != last12.last) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final e in last12) ...[
                Expanded(
                  child: Text(
                    _shortMonth(e.key),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.6),
                      fontSize: 9,
                    ),
                  ),
                ),
                if (e != last12.last) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortMonth(String key) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final parts = key.split('-');
    if (parts.length < 2) return key;
    final m = int.tryParse(parts[1]) ?? 0;
    return months[m.clamp(0, 12)];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.count, required this.maxCount});
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final frac = count / maxCount;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (count > 0)
          Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.7),
              fontSize: 8,
            ),
          ),
        const SizedBox(height: 2),
        Flexible(
          flex: (frac * 100).round().clamp(1, 100),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Flexible(
          flex: ((1 - frac) * 100).round().clamp(0, 99),
          child: const SizedBox(),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.filmDim.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontFamily: AppText.monoFontFamily,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.filmDim.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
    );
  }
}
