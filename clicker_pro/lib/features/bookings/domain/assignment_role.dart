// lib/features/bookings/domain/assignment_role.dart
//
// Per-assignment role on a booking. Distinct from [UserRole] (which is the
// platform-wide identity tier) — an `Assignment` can pin any team member to
// a specific on-shoot role like cinematographer or drone operator,
// independent of their user role.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 7.4.

/// The role a team member fills on a specific [Assignment].
///
/// Persisted as the camelCase [name] string in both Drift
/// (`AssignmentsTable.role`) and Postgres (`Assignment.role`).
enum AssignmentRole {
  chiefPhotographer,
  photographer,
  cinematographer,
  editor,
  assistant,
  drone;

  /// Parses a camelCase assignment-role string back into an
  /// [AssignmentRole].
  ///
  /// Accepts exactly the six enum [name] strings: `'chiefPhotographer'`,
  /// `'photographer'`, `'cinematographer'`, `'editor'`, `'assistant'`,
  /// `'drone'`. Throws [ArgumentError] for any other input so callers
  /// fail fast on corrupt data.
  static AssignmentRole fromString(String value) {
    for (final role in AssignmentRole.values) {
      if (role.name == value) return role;
    }
    throw ArgumentError.value(value, 'value', 'Unknown AssignmentRole');
  }
}
