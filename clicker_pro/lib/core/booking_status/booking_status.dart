// lib/core/booking_status/booking_status.dart
//
// Booking status enum + display helpers for the bookings module.
//
// Pure Dart enum plus a small extension. This file imports nothing from
// Drift, Riverpod, or any I/O package — only `flutter/widgets.dart` for
// [BuildContext] (and the generated [AppLocalizations]) so it can be reused
// by domain models, repositories, and widgets without dragging in
// infrastructure.
//
// See specs/bookings-module/design.md — "Booking Status Machine" + the
// status-color contract referenced from Requirement 1.13 / 3.1–3.3.

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// The lifecycle status of a Booking (Event).
///
/// Drives the badge color on list rows and detail headers, gates allowed
/// transitions in [BookingStatusMachine], and is persisted as the camelCase
/// [name] string in both Drift (`BookingsTable.status`) and Postgres
/// (`Event.status`).
///
/// The seven values match the architecture document and the backend Prisma
/// schema exactly. Order is the canonical forward-progression order; the
/// terminal `cancelled` value sits at the end and may be entered from any
/// non-terminal state per Requirement 3.2.
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  shotComplete,
  delivered,
  completed,
  cancelled;

  /// Parses a camelCase status string back into a [BookingStatus].
  ///
  /// Accepts exactly the seven enum [name] strings: `'pending'`,
  /// `'confirmed'`, `'inProgress'`, `'shotComplete'`, `'delivered'`,
  /// `'completed'`, `'cancelled'`. Throws [ArgumentError] for any other
  /// input so callers (DAOs, serializers) fail fast on corrupt data rather
  /// than silently coercing to a wrong value.
  static BookingStatus fromString(String value) {
    for (final status in BookingStatus.values) {
      if (status.name == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown BookingStatus');
  }
}

/// Localized display helpers for [BookingStatus].
///
/// Kept as an extension (not a method on the enum) so the enum itself stays
/// pure-Dart and can be referenced from contexts that do not have a
/// [BuildContext] available — generators, tests, JSON serializers.
extension BookingStatusDisplay on BookingStatus {
  /// Returns the localized display label for this status.
  ///
  /// Looks up the label via [AppLocalizations.of] so it tracks the active
  /// locale and re-renders when the language toggle flips. The dedicated
  /// ARB keys (`bookingStatusPending`, `bookingStatusConfirmed`,
  /// `bookingStatusInProgress`, `bookingStatusShotComplete`,
  /// `bookingStatusDelivered`, `bookingStatusCompleted`,
  /// `bookingStatusCancelled`) land in task 10.1 of this module; until they
  /// land, this falls back to the capitalized [name] so the file compiles
  /// and renders sensibly standalone.
  String displayName(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (this) {
      case BookingStatus.pending:
        return loc.bookingStatusPending;
      case BookingStatus.confirmed:
        return loc.bookingStatusConfirmed;
      case BookingStatus.inProgress:
        return loc.bookingStatusInProgress;
      case BookingStatus.shotComplete:
        return loc.bookingStatusShotComplete;
      case BookingStatus.delivered:
        return loc.bookingStatusDelivered;
      case BookingStatus.completed:
        return loc.bookingStatusCompleted;
      case BookingStatus.cancelled:
        return loc.bookingStatusCancelled;
    }
  }
}
