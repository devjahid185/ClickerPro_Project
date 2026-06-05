// lib/features/push/domain/push_token_payload.dart
//
// Plain DTO sent to `POST /api/devices/register`।  Pure Dart so we can
// unit-test without Firebase / platform plugins।
//
// `platform` is a raw string ('android' | 'ios' | 'web') — kept loose
// instead of an enum so the backend can introduce new platforms (e.g.
// 'macos') without a Flutter release।

class PushTokenPayload {
  final String token;
  final String platform;
  final String? appVersion;
  final String? language;

  const PushTokenPayload({
    required this.token,
    required this.platform,
    this.appVersion,
    this.language,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
    if (language != null) 'language': language,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PushTokenPayload &&
          token == other.token &&
          platform == other.platform &&
          appVersion == other.appVersion &&
          language == other.language);

  @override
  int get hashCode => Object.hash(token, platform, appVersion, language);
}
