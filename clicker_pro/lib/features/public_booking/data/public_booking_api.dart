// lib/features/public_booking/data/public_booking_api.dart
//
// Wire-level methods for the Public Booking endpoints. Has two faces:
//
//   * Owner-side (authenticated): issue tokens, list pending requests,
//     approve, reject. The studio's bearer token is attached automatically
//     by `ApiClient` when present.
//
//   * Visitor-side (unauthenticated): peek at a token, submit a request.
//     The opaque HMAC token in the `?token=` query parameter IS the only
//     credential — these calls pass `authenticated: false` so `ApiClient`
//     does NOT inject the studio's Bearer header.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirements 13.14, 13.15.

import '../../../core/network/api_client.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_token.dart';

class PublicBookingApi {
  PublicBookingApi(this._client);

  final ApiClient _client;

  // ---------------------------------------------------------------------
  // Owner-side (authenticated)
  // ---------------------------------------------------------------------

  /// `POST /api/team/public-booking-tokens` — issue a fresh public link.
  Future<({String url, String token, DateTime expiresAt})> issueToken({
    int? expiresInDays,
    int? maxUses,
  }) async {
    final r =
        await _client.post(
              '/api/team/public-booking-tokens',
              body: {'expiresInDays': ?expiresInDays, 'maxUses': ?maxUses},
            )
            as Map<String, dynamic>;
    return (
      url: r['url'] as String,
      token: r['token'] as String,
      expiresAt: DateTime.parse(r['expiresAt'] as String),
    );
  }

  /// `GET /api/bookings/pending-public` — list pending submissions.
  Future<List<PublicBookingRequest>> listPending() async {
    final r =
        await _client.get('/api/bookings/pending-public')
            as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map(
          (e) =>
              PublicBookingRequest.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  /// `POST /api/bookings/pending-public/:requestId/approve` — promote a
  /// pending request to a real Event server-side. Returns the freshly
  /// materialized event payload as a raw map; the repository decodes it
  /// via `Booking.fromJson` (avoids a circular import on the booking
  /// domain layer).
  Future<Map<String, dynamic>> approve(String requestId) async {
    final r =
        await _client.post('/api/bookings/pending-public/$requestId/approve')
            as Map<String, dynamic>;
    return (r['event'] as Map).cast<String, dynamic>();
  }

  /// `POST /api/bookings/pending-public/:requestId/reject`.
  Future<PublicBookingRequest> reject(
    String requestId, {
    String? reason,
  }) async {
    final r =
        await _client.post(
              '/api/bookings/pending-public/$requestId/reject',
              body: {'reason': ?reason},
            )
            as Map<String, dynamic>;
    return PublicBookingRequest.fromJson(
      (r['request'] as Map).cast<String, dynamic>(),
    );
  }

  // ---------------------------------------------------------------------
  // Visitor-side (unauthenticated — token in query string is the credential)
  // ---------------------------------------------------------------------

  /// `GET /api/public/booking?token=` — visitor peeks at the token's
  /// branding + supported event types. `authenticated: false` so no
  /// Bearer header is attached.
  Future<PublicBookingToken> peek(String token) async {
    final r =
        await _client.get(
              '/api/public/booking',
              query: {'token': token},
              authenticated: false,
            )
            as Map<String, dynamic>;
    // The server response shape is `{ studioName, studioLogoUrl?,
    // supportedEventTypes, locale, expiresAt }`. The `token` itself is
    // not echoed — we splice the caller's token back in so the resulting
    // `PublicBookingToken` is self-contained for the submit step.
    return PublicBookingToken.fromJson({...r, 'token': token});
  }

  /// `POST /api/public/booking?token=` — visitor submits a request.
  /// Returns the server-issued `requestId` for the success screen.
  Future<String> submit(String token, PublicBookingRequest payload) async {
    final r =
        await _client.post(
              '/api/public/booking?token=${Uri.encodeQueryComponent(token)}',
              body: payload.toJson(),
              authenticated: false,
            )
            as Map<String, dynamic>;
    return r['requestId'] as String;
  }
}
