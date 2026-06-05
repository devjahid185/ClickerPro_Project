// lib/features/bookings/domain/booking_sort.dart
//
// Sort order applied to the booking list query. Selected by the user from
// the list-screen sort menu and threaded through `BookingFilter` so it
// participates in the keyed `bookingListProvider` family.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 1.3, 1.6.

/// The sort order applied to the booking list.
///
/// Default is [dateDesc] — the most recently scheduled events first — to
/// match the calendar / dashboard "upcoming first" convention.
enum BookingSort {
  dateDesc,
  dateAsc,
  createdAtDesc,
  clientNameAsc;

  /// Parses a camelCase booking-sort string back into a [BookingSort].
  ///
  /// Accepts exactly the four enum [name] strings: `'dateDesc'`,
  /// `'dateAsc'`, `'createdAtDesc'`, `'clientNameAsc'`. Throws
  /// [ArgumentError] for any other input so callers fail fast on corrupt
  /// data.
  static BookingSort fromString(String value) {
    for (final sort in BookingSort.values) {
      if (sort.name == value) return sort;
    }
    throw ArgumentError.value(value, 'value', 'Unknown BookingSort');
  }
}
