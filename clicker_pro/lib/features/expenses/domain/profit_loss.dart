// lib/features/expenses/domain/profit_loss.dart
//
// Snapshot record returned by `GET /api/expenses/profit`.  The backend
// expression:
//
//   netProfit = totalIncome - totalExpense
//
// where `totalIncome` is the sum of payments where the caller is the
// `recipientId`, and `totalExpense` is the sum of expenses owned by the
// caller।
//
// All amounts are major-unit currency floats — formatting happens at the
// view layer via `BookingFormat.money`.

class ProfitLoss {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;

  const ProfitLoss({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
  });

  /// Backend response sample:
  ///   { success: true,
  ///     totalIncome: { _sum: { amount: 100000 } },  // ← Prisma raw shape
  ///     totalExpense: 35000,
  ///     netProfit: 65000 }
  ///
  /// `totalIncome` arrives as the raw Prisma aggregate object (because the
  /// controller forgot to unwrap `_sum.amount`), so we tolerate both
  /// shapes here.  Once the backend is updated, the wrapped path drops
  /// out automatically.
  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      totalIncome: _readAmount(json['totalIncome']),
      totalExpense: _readAmount(json['totalExpense']),
      netProfit: _readAmount(json['netProfit']),
    );
  }

  static double _readAmount(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    if (raw is Map) {
      final sum = raw['_sum'];
      if (sum is Map) {
        final amount = sum['amount'];
        if (amount is num) return amount.toDouble();
      }
      // direct `{ amount: ... }` fallback
      final direct = raw['amount'];
      if (direct is num) return direct.toDouble();
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfitLoss) return false;
    return totalIncome == other.totalIncome &&
        totalExpense == other.totalExpense &&
        netProfit == other.netProfit;
  }

  @override
  int get hashCode => Object.hash(totalIncome, totalExpense, netProfit);

  @override
  String toString() =>
      'ProfitLoss(income: $totalIncome, expense: $totalExpense, '
      'net: $netProfit)';
}
