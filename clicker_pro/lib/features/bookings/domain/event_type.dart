// lib/features/bookings/domain/event_type.dart
//
// Event/booking category. Drives the "bride/groom required" form rule on
// the new/edit booking screen and the supported-event-types filter on
// public booking forms.
//
// Pure Dart enum — no Flutter, Drift, or Riverpod imports — so it can be
// safely referenced from domain models, serializers, and property tests.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 1.3, 1.6, 2.1, 2.2.

/// The kind of event a [Booking] represents.
///
/// The seven values match the architecture document and the backend Prisma
/// schema exactly. Persisted as the camelCase [name] string in both Drift
/// (`BookingsTable.eventType`) and Postgres (`Event.eventType`).
enum EventType {
  wedding,
  holud,
  birthday,
  corporate,
  preWedding,
  anniversary,
  outdoor,
  other;

  /// Parses a camelCase event-type string back into an [EventType].
  ///
  /// Accepts exactly the six enum [name] strings: `'wedding'`, `'holud'`,
  /// `'birthday'`, `'corporate'`, `'preWedding'`, `'other'`. Throws
  /// [ArgumentError] for any other input so callers fail fast on corrupt
  /// data rather than silently coercing to a wrong value.
  static EventType fromString(String value) {
    for (final type in EventType.values) {
      if (type.name == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown EventType');
  }

  /// True iff this event type requires the bride / groom name fields on
  /// the new/edit booking form (Requirement 2.2).
  ///
  /// Only `wedding` and `holud` set this; every other event type leaves
  /// those fields optional.
  bool get requiresBrideGroom => this == wedding || this == holud;
}
