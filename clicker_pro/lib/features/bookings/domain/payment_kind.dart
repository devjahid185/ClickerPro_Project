// lib/features/bookings/domain/payment_kind.dart
//
// The kind of payment recorded against a booking. Distinguishes the
// standard advance / due split from out-of-band extras so the finance
// summary can break them out separately.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 1.3, 13.1.

/// The kind of [Payment] entry on a booking.
///
/// Persisted as the camelCase [name] string in both Drift
/// (`PaymentsTable.kind`) and Postgres (`Payment.kind`).
enum PaymentKind {
  advance,
  due,
  extra;

  /// Parses a camelCase payment-kind string back into a [PaymentKind].
  ///
  /// Accepts exactly the three enum [name] strings: `'advance'`, `'due'`,
  /// `'extra'`. Throws [ArgumentError] for any other input so callers fail
  /// fast on corrupt data.
  static PaymentKind fromString(String value) {
    for (final kind in PaymentKind.values) {
      if (kind.name == value) return kind;
    }
    throw ArgumentError.value(value, 'value', 'Unknown PaymentKind');
  }
}
