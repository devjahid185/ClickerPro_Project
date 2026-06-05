// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import '../../bookings/domain/booking.dart';
import 'public_booking_request.dart';
import 'public_booking_token.dart';

/// Public-booking flow: owner-side token issuance + approve/reject of
/// pending visitor submissions, and visitor-side (unauthenticated)
/// peek + submit against an HMAC token.
///
/// Owner-side methods verify the corresponding Capability
/// (`generatePublicBookingToken`, `approvePublicBooking`) via the
/// supplied [RolePolicy]. Visitor-side methods do NOT call any role
/// check; they rely on the server's HMAC token verification.
abstract class PublicBookingRepository {
  // -- Owner side ----------------------------------------------------------

  /// Issues a token for the current studio.
  ///
  /// Returns a record with the public URL the visitor opens, the opaque
  /// token (for analytics / re-share), and the server-enforced
  /// expiration timestamp.
  Future<({String url, String token, DateTime expiresAt})> issueToken({
    required RolePolicy policy,
  });

  // -- Visitor side --------------------------------------------------------

  /// Peeks at token validity without authentication. Returns the studio
  /// branding metadata the public form renders.
  Future<PublicBookingToken> peek(String token);

  /// Submits a booking request. Returns the server-issued request id.
  Future<String> submit({
    required String token,
    required PublicBookingRequest payload,
  });

  // -- Owner side: pending list + approve/reject ---------------------------

  /// Live local-first list of pending requests for the current studio.
  Stream<List<PublicBookingRequest>> watchPending();

  /// Pulls fresh pending requests from the server and reconciles into
  /// Drift.
  Future<void> refreshPending();

  /// Approves a pending request. Returns the materialized [Booking].
  Future<Booking> approve(String requestId, {required RolePolicy policy});

  /// Rejects a pending request.
  Future<void> reject(String requestId, {required RolePolicy policy});
}
