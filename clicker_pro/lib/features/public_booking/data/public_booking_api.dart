// lib/features/public_booking/data/public_booking_api.dart
//
// Public Booking endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + PublicBookingController):
//   GET  /api/public-booking/{token}  → { data: { studio, packages } }
//   POST /api/public-booking/{token}  → { data: event } (201)
//
// The owner's share link uses the `public_booking_token` already issued
// on the user account (UserResource exposes it as bookingToken). Visitor
// submissions become PENDING bookings directly server-side, so they show
// up in the normal bookings list — there is no separate pending-requests
// queue on this backend, and [listPending] reflects that by returning
// empty.

import '../../../core/env/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../bookings/domain/event_type.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_token.dart';

class PublicBookingApi {
  PublicBookingApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _data(dynamic r) {
    if (r is! Map) return <String, dynamic>{};
    final d = r['data'];
    return (d is Map ? d : r).cast<String, dynamic>();
  }

  // ---------------------------------------------------------------------
  // Owner-side (authenticated)
  // ---------------------------------------------------------------------

  /// Returns the owner's permanent public-booking link. The token lives
  /// on the user account (issued at registration); there is no rotating
  /// token endpoint on this backend yet.
  Future<({String url, String token, DateTime expiresAt})> issueToken({
    int? expiresInDays,
    int? maxUses,
  }) async {
    final r = await _client.get('/api/profile');
    final d = _data(r);
    final u = d['user'] is Map
        ? (d['user'] as Map).cast<String, dynamic>()
        : d;
    final token =
        (u['bookingToken'] ?? u['public_booking_token'] ?? u['publicToken'] ?? '')
            .toString();
    return (
      url: '${AppConfig.baseUrl}/api/public-booking/$token',
      token: token,
      // The account token does not expire — surface a far-future date so
      // the share sheet renders something sensible.
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// Visitor submissions become PENDING bookings directly on this
  /// backend — they appear in the main bookings list, so the separate
  /// pending queue is always empty.
  Future<List<PublicBookingRequest>> listPending() async {
    return const [];
  }

  /// Not applicable on this backend (submissions are already bookings) —
  /// kept for interface compatibility; never reachable while
  /// [listPending] returns empty.
  Future<Map<String, dynamic>> approve(String requestId) async {
    throw UnsupportedError(
      'Public submissions are created as PENDING bookings directly.',
    );
  }

  Future<PublicBookingRequest> reject(
    String requestId, {
    String? reason,
  }) async {
    throw UnsupportedError(
      'Public submissions are created as PENDING bookings directly.',
    );
  }

  // ---------------------------------------------------------------------
  // Visitor-side (unauthenticated — token in the path is the credential)
  // ---------------------------------------------------------------------

  /// `GET /api/public-booking/{token}` — visitor peeks at the studio's
  /// branding. `authenticated: false` so no Bearer header is attached.
  Future<PublicBookingToken> peek(String token) async {
    final r = await _client.get(
      '/api/public-booking/$token',
      authenticated: false,
    );
    final d = _data(r);
    final studio = d['studio'] is Map
        ? (d['studio'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return PublicBookingToken(
      token: token,
      studioName: (studio['name'] ?? 'Studio').toString(),
      studioLogoUrl: studio['avatar'] as String?,
      // The backend accepts any event type on submit.
      supportedEventTypes: EventType.values.toSet(),
      locale: 'en',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// `POST /api/public-booking/{token}` — visitor submits a request.
  /// Returns the created PENDING booking's id.
  Future<String> submit(String token, PublicBookingRequest payload) async {
    final r = await _client.post(
      '/api/public-booking/$token',
      body: {
        'name': payload.clientName,
        'phone': payload.clientPhone,
        'email': ?payload.clientEmail,
        'event_type': payload.eventType.name,
        'date': payload.date.toIso8601String().split('T').first,
        'venue': ?payload.venue,
        'notes': ?payload.notes,
      },
      authenticated: false,
    );
    final d = _data(r);
    return (d['id'] ?? '').toString();
  }
}
