// lib/features/reports/domain/yearly_summary.dart
//
// Snapshot record returned by `GET /api/reports/yearly-summary?year=YYYY`।
//
// Backend response shape (controllers/reportController.js):
//   {
//     year: "2025",
//     summary: {
//       totalRevenue: 500000,
//       totalExpenses: 80000,
//       totalFreelancerPayouts: 120000,
//       netProfit: 300000          // = revenue - (expenses + payouts)
//     }
//   }
//
// All amounts are major-unit currency floats — formatting happens at the
// view layer via `BookingFormat.money`।

class YearlySummary {
  final String year;
  final double totalRevenue;
  final double totalExpenses;
  final double totalFreelancerPayouts;
  final double netProfit;

  const YearlySummary({
    required this.year,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalFreelancerPayouts,
    required this.netProfit,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> json) {
    final year = json['year']?.toString() ?? '';
    final summary =
        (json['summary'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return YearlySummary(
      year: year,
      totalRevenue: _readNum(summary['totalRevenue']),
      totalExpenses: _readNum(summary['totalExpenses']),
      totalFreelancerPayouts: _readNum(summary['totalFreelancerPayouts']),
      netProfit: _readNum(summary['netProfit']),
    );
  }

  static double _readNum(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  /// Sanity invariant: `revenue - (expenses + payouts) == netProfit`,
  /// modulo floating-point rounding।  Useful in tests + UI integrity
  /// checks।  Not used at runtime by the view tier — surfaced for
  /// optional debug overlays।
  bool get isInternallyConsistent {
    final expected = totalRevenue - (totalExpenses + totalFreelancerPayouts);
    return (expected - netProfit).abs() < 0.01;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! YearlySummary) return false;
    return year == other.year &&
        totalRevenue == other.totalRevenue &&
        totalExpenses == other.totalExpenses &&
        totalFreelancerPayouts == other.totalFreelancerPayouts &&
        netProfit == other.netProfit;
  }

  @override
  int get hashCode => Object.hash(
    year,
    totalRevenue,
    totalExpenses,
    totalFreelancerPayouts,
    netProfit,
  );
}
