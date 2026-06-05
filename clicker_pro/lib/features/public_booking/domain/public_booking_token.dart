// lib/features/public_booking/domain/public_booking_token.dart
//
// Unauthenticated visitor view of a public booking link.
//
// The visitor never sees the studio's bearer token. Instead they hit the
// `/api/public/booking?token=...` peek endpoint with the opaque, HMAC-signed
// token issued by the Owner; the server responds with this object so the form
// can be branded, locale-configured, and gated to the studio's supported
// event types.

import '../../bookings/domain/event_type.dart';

class PublicBookingToken {
  const PublicBookingToken({
    required this.token,
    required this.studioName,
    required this.supportedEventTypes,
    required this.locale,
    required this.expiresAt,
    this.studioLogoUrl,
  });

  /// The opaque token string the visitor passes back on submit.
  final String token;

  /// Studio display name shown at the top of the public form.
  final String studioName;

  /// Optional logo to render in the form header.
  final String? studioLogoUrl;

  /// Which event types the studio accepts via the public form.
  final Set<EventType> supportedEventTypes;

  /// `'en'` or `'bn'`; defaults to `'en'` server-side when not configured.
  final String locale;

  /// Server-enforced expiry. Visitor-side check is informational only.
  final DateTime expiresAt;

  PublicBookingToken copyWith({
    String? token,
    String? studioName,
    String? studioLogoUrl,
    Set<EventType>? supportedEventTypes,
    String? locale,
    DateTime? expiresAt,
  }) {
    return PublicBookingToken(
      token: token ?? this.token,
      studioName: studioName ?? this.studioName,
      studioLogoUrl: studioLogoUrl ?? this.studioLogoUrl,
      supportedEventTypes: supportedEventTypes ?? this.supportedEventTypes,
      locale: locale ?? this.locale,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'studioName': studioName,
    if (studioLogoUrl != null) 'studioLogoUrl': studioLogoUrl,
    'supportedEventTypes': supportedEventTypes
        .map((e) => e.name)
        .toList(growable: false),
    'locale': locale,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory PublicBookingToken.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['supportedEventTypes'];
    final types = <EventType>{};
    if (rawTypes is Iterable) {
      for (final raw in rawTypes) {
        if (raw is String) types.add(EventType.fromString(raw));
      }
    }
    return PublicBookingToken(
      token: json['token'] as String,
      studioName: json['studioName'] as String,
      studioLogoUrl: json['studioLogoUrl'] as String?,
      supportedEventTypes: types,
      locale: (json['locale'] as String?) ?? 'en',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PublicBookingToken) return false;
    return other.token == token &&
        other.studioName == studioName &&
        other.studioLogoUrl == studioLogoUrl &&
        _setEquals(other.supportedEventTypes, supportedEventTypes) &&
        other.locale == locale &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(
    token,
    studioName,
    studioLogoUrl,
    // Order-independent hash for the supported-types set.
    Object.hashAllUnordered(supportedEventTypes),
    locale,
    expiresAt,
  );

  static bool _setEquals(Set<EventType> a, Set<EventType> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
