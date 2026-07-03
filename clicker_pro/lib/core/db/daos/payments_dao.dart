// lib/core/db/daos/payments_dao.dart
//
// DAO for Payments. Exposes per-booking aggregation in addition to standard
// CRUD; the aggregation result powers the payment summary card on the Booking
// Detail screen and the payment chip on each list row.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/payments_table.dart';

part 'payments_dao.g.dart';

/// Aggregate of payments for a single booking, broken down by [PaymentKind]
/// and summed into [total]. The repository surface re-exposes this via a
/// record type matching the public API.
class BookingPaymentAggregate {
  final double advance;
  final double due;
  final double extra;
  final double total;

  const BookingPaymentAggregate({
    required this.advance,
    required this.due,
    required this.extra,
    required this.total,
  });

  static const empty = BookingPaymentAggregate(
    advance: 0,
    due: 0,
    extra: 0,
    total: 0,
  );
}

@DriftAccessor(tables: [PaymentsTable])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Stream<List<PaymentRow>> watchByBooking(String bookingId) {
    return (select(paymentsTable)
          ..where((t) => t.bookingId.equals(bookingId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<void> upsert(PaymentsTableCompanion row) async {
    await into(paymentsTable).insertOnConflictUpdate(row);
  }

  /// Sum of payments collected in `[from, to)` grouped by payment method
  /// (cash / bkash / bank / …). Powers the "which channel" breakdown on the
  /// dashboard's Today Collection card. A null method is bucketed as 'cash'
  /// (the historical default). Bucketed by `createdAt` — a payment is recorded
  /// at the moment it's collected.
  Future<Map<String, double>> collectionByMethodBetween(
    DateTime from,
    DateTime to,
  ) async {
    final when = paymentsTable.createdAt;
    final sumExpr = paymentsTable.amount.sum();
    final query = selectOnly(paymentsTable)
      ..addColumns([paymentsTable.method, sumExpr])
      ..where(when.isBiggerOrEqualValue(from) & when.isSmallerThanValue(to))
      ..groupBy([paymentsTable.method]);

    final result = <String, double>{};
    for (final row in await query.get()) {
      final method = (row.read(paymentsTable.method) ?? 'cash').toLowerCase();
      final value = row.read<double>(sumExpr) ?? 0;
      result[method] = (result[method] ?? 0) + value;
    }
    return result;
  }

  Future<void> deleteById(String id) async {
    await (delete(paymentsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Returns `(advance, due, extra, total)` for [bookingId]. Each component is
  /// the SUM of payments of the matching `kind`; `total = advance + due +
  /// extra`. Returns zeroed components when the booking has no payments.
  Future<({double advance, double due, double extra, double total})>
      aggregateForBooking(String bookingId) async {
    final amount = paymentsTable.amount;
    final sumExpr = amount.sum();
    final query = selectOnly(paymentsTable)
      ..addColumns([paymentsTable.kind, sumExpr])
      ..where(paymentsTable.bookingId.equals(bookingId))
      ..groupBy([paymentsTable.kind]);

    double advance = 0;
    double due = 0;
    double extra = 0;
    final rows = await query.get();
    for (final row in rows) {
      final kind = row.read(paymentsTable.kind);
      final value = row.read<double>(sumExpr) ?? 0;
      switch (kind) {
        case 'advance':
          advance = value;
          break;
        case 'due':
          due = value;
          break;
        case 'extra':
          extra = value;
          break;
      }
    }
    return (
      advance: advance,
      due: due,
      extra: extra,
      total: advance + due + extra,
    );
  }
}
