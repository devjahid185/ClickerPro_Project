// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import 'payment.dart';

/// Payment CRUD scoped to a single booking, plus the aggregate
/// computation used by the detail screen's payment-summary card.
///
/// Mutations are gated on the `editBookingPayments` Capability via the
/// supplied [RolePolicy].
abstract class PaymentRepository {
  /// Live local-first list of all payments for a booking.
  Stream<List<Payment>> watchByBooking(String bookingId);

  /// One-shot aggregate of payments for a booking.
  ///
  /// Returns a record with the per-kind totals plus the grand total,
  /// satisfying the invariant `advance + due + paid + extra == total`.
  Future<
    ({double advance, double due, double paid, double extra, double total})
  >
  aggregateForBooking(String bookingId);

  /// Amounts collected in `[from, to)` grouped by payment method
  /// (cash/bkash/bank/…). Powers the dashboard collection breakdown.
  Future<Map<String, double>> collectionByMethodBetween(
    DateTime from,
    DateTime to,
  );

  /// Adds a new payment. Verifies `editBookingPayments`.
  Future<void> add(Payment p, {required RolePolicy policy});

  /// Updates an existing payment. Verifies `editBookingPayments`.
  Future<void> update(Payment p, {required RolePolicy policy});

  /// Removes a payment by id. Verifies `editBookingPayments`.
  Future<void> remove(String paymentId, {required RolePolicy policy});
}
