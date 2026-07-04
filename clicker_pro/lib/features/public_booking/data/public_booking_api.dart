// lib/features/public_booking/data/public_booking_api.dart
//
// Public Booking endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + PublicBookingController):
//   GET  /api/public-booking/{token}            → { data: { studio, packages } }
//   POST /api/public-booking/{token}            → { data: request } (201)
//   GET  /api/public-booking-requests           → { data: [request…] } (owner)
//   POST /api/public-booking-requests/{id}/approve → { data: event } (owner)
//   POST /api/public-booking-requests/{id}/reject  → { data: request } (owner)
//
// The owner's share link uses the `public_booking_token` already issued
// on the user account (UserResource exposes it as bookingToken). Visitor
// submissions land in the owner's pending-requests queue (with a push
// notification); approving one creates the PENDING event.

import '../../../core/env/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../bookings/domain/event_type.dart';
import '../../bookings/domain/shift.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_request_status.dart';
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
      // The shareable link must open the WEB booking form, not the raw
      // JSON API endpoint — clients tap this from WhatsApp/SMS.
      url: '${AppConfig.webBaseUrl}/book/$token',
      token: token,
      // The account token does not expire — surface a far-future date so
      // the share sheet renders something sensible.
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// `GET /api/public-booking-requests` — the owner's review queue of
  /// visitor submissions awaiting approve/reject.
  Future<List<PublicBookingRequest>> listPending() async {
    final r = await _client.get('/api/public-booking-requests');
    final raw = (r is Map ? r['data'] : null) as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => _requestFromServer(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/public-booking-requests/{id}/approve` — promotes the
  /// request to a PENDING event server-side and returns the event row.
  Future<Map<String, dynamic>> approve(String requestId) async {
    final r = await _client.post(
      '/api/public-booking-requests/$requestId/approve',
    );
    return _data(r);
  }

  Future<PublicBookingRequest> reject(
    String requestId, {
    String? reason,
  }) async {
    final r = await _client.post(
      '/api/public-booking-requests/$requestId/reject',
    );
    return _requestFromServer(_data(r));
  }

  /// Maps a Laravel `public_booking_requests` row onto the richer local
  /// domain model. The public form doesn't collect times/shift, so those
  /// fall back to the day-shift defaults; unknown event types coerce to
  /// [EventType.other] rather than throwing on foreign data.
  PublicBookingRequest _requestFromServer(Map<String, dynamic> j) {
    EventType eventType;
    try {
      eventType = EventType.fromString((j['event_type'] ?? '').toString());
    } on ArgumentError {
      eventType = EventType.other;
    }
    final name = (j['name'] ?? j['clientName'] ?? '—').toString();
    final submitted = DateTime.tryParse((j['created_at'] ?? '').toString());
    final updated = DateTime.tryParse((j['updated_at'] ?? '').toString());
    return PublicBookingRequest(
      id: (j['id'] ?? '').toString(),
      studioId: (j['owner_id'] ?? '').toString(),
      title: '${eventType.name} - $name',
      eventType: eventType,
      date:
          DateTime.tryParse((j['date'] ?? '').toString()) ?? DateTime.now(),
      startTime: '12:00',
      endTime: '17:00',
      shift: Shift.day,
      venue: j['venue'] as String?,
      clientName: name,
      clientPhone: (j['phone'] ?? '').toString(),
      clientEmail: j['email'] as String?,
      notes: j['notes'] as String?,
      status: PublicBookingRequestStatus.fromString(
        (j['status'] as String?)?.toLowerCase(),
      ),
      submittedAt: submitted ?? DateTime.now(),
      updatedAt: updated ?? submitted ?? DateTime.now(),
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
