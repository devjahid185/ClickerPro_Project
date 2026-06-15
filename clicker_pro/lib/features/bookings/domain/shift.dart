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

  /// Canonical start time ("HH:mm") for the shift.
  /// Day shift  = 12:00 PM (noon) → 17:00 (5 PM).
  /// Night shift = 18:00 (6 PM)   → 23:00 (11 PM).
  /// Both        = full day, 12:00 → 23:00.
  String get defaultStartTime => switch (this) {
    Shift.day => '12:00',
    Shift.night => '18:00',
    Shift.both => '12:00',
  };

  /// Canonical end time ("HH:mm") for the shift. See [defaultStartTime].
  String get defaultEndTime => switch (this) {
    Shift.day => '17:00',
    Shift.night => '23:00',
    Shift.both => '23:00',
  };
}
