// lib/features/bookings/domain/shift.dart
//
// Coverage shift on a booking — distinguishes day-only, night-only, and
// full-day (both) shoots for scheduling and pricing.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 1.6, 2.1.

/// The coverage shift for a [Booking].
///
/// Persisted as the camelCase [name] string in both Drift
/// (`BookingsTable.shift`) and Postgres (`Event.shift`).
enum Shift {
  day,
  night,
  both;

  /// Parses a camelCase shift string back into a [Shift].
  ///
  /// Accepts exactly the three enum [name] strings: `'day'`, `'night'`,
  /// `'both'`. Throws [ArgumentError] for any other input so callers fail
  /// fast on corrupt data.
  static Shift fromString(String value) {
    for (final shift in Shift.values) {
      if (shift.name == value) return shift;
    }
    throw ArgumentError.value(value, 'value', 'Unknown Shift');
  }
}
