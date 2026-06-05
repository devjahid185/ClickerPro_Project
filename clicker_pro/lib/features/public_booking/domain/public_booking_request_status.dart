// lib/features/public_booking/domain/public_booking_request_status.dart
//
// Lifecycle of a Public Booking Request as it sits in the Owner's pending
// queue before it is promoted to a real Event (via approve) or discarded
// (via reject). Mirrors the backend `PublicBookingRequestStatus`.

enum PublicBookingRequestStatus {
  pending,
  approved,
  rejected;

  /// Parses a wire-format string (`'pending' | 'approved' | 'rejected'`) into
  /// the enum value. Falls back to [fallback] (default: [pending]) when the
  /// input is null or unrecognised, so foreign payloads cannot crash callers.
  static PublicBookingRequestStatus fromString(
    String? raw, {
    PublicBookingRequestStatus fallback = PublicBookingRequestStatus.pending,
  }) {
    if (raw == null) return fallback;
    final lower = raw.toLowerCase();
    for (final s in PublicBookingRequestStatus.values) {
      if (s.name.toLowerCase() == lower) return s;
    }
    return fallback;
  }

  /// Wire format used by backend payloads.
  String get wireName => name;
}
