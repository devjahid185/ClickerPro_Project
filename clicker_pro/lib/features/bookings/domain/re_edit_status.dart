// lib/features/bookings/domain/re_edit_status.dart
//
// The lifecycle status of a re-edit request raised against a delivered
// booking.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 7.4.

/// The lifecycle status of a [ReEditRequest].
///
/// Persisted as the camelCase [name] string in both Drift
/// (`ReEditRequestsTable.status`) and Postgres (`ReEditRequest.status`).
///
/// `pending` and `inProgress` are the "open" tier — a request in either
/// state can become overdue once its `deadline` passes. `done` and
/// `rejected` are terminal.
enum ReEditStatus {
  pending,
  inProgress,
  done,
  rejected;

  /// Parses a camelCase re-edit status string back into a [ReEditStatus].
  ///
  /// Accepts exactly the four enum [name] strings: `'pending'`,
  /// `'inProgress'`, `'done'`, `'rejected'`. Throws [ArgumentError] for any
  /// other input so callers fail fast on corrupt data.
  static ReEditStatus fromString(String value) {
    for (final status in ReEditStatus.values) {
      if (status.name == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown ReEditStatus');
  }
}
