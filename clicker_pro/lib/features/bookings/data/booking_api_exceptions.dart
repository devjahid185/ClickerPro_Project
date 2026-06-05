// lib/features/bookings/data/booking_api_exceptions.dart
//
// Typed exceptions thrown by the booking-side `*Api` classes on top of
// the generic `ApiException` from the network layer. Surfaced to
// repositories so they can drive the conflict-reconciliation UX without
// pattern-matching on raw HTTP status codes.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" + "Conflict Resolution Rules".

import '../../../core/booking_status/booking_status.dart';

/// Thrown by `BookingApi.transitionStatus` when the server replies with
/// HTTP 409, indicating the booking's current status on the server does
/// NOT match the supplied `fromStatus`.
///
/// The repository catches this, drops the local pending statusHistory
/// row, refreshes the booking from the remote, and emits a non-blocking
/// reconciliation event on the `statusConflictStream`.
///
/// `serverStatus` is the booking's actual current status on the server,
/// parsed from the 409 response body. Callers should adopt this value
/// instead of the locally-attempted `to`.
class StatusConflictException implements Exception {
  const StatusConflictException({required this.serverStatus, this.message});

  /// The booking's actual current status on the server.
  final BookingStatus serverStatus;

  /// Optional server-supplied human-readable message.
  final String? message;

  @override
  String toString() =>
      'StatusConflictException(serverStatus: ${serverStatus.name}'
      '${message == null ? '' : ', message: $message'})';
}
