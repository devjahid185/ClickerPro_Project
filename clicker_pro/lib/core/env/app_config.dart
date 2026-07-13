// lib/core/env/app_config.dart
//
// Runtime environment configuration. Values are read from the .env file
// (loaded in main.dart via dotenv.load) first, then overridden by any
// compile-time --dart-define, falling back to a safe default.
//
// Physical devices must use ADB reverse (adb reverse tcp:5000 tcp:5000)
// or the PC's LAN IP to reach the backend — never 127.0.0.1, which on a
// phone points at the phone itself.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// Reads [key] from the loaded .env file, falling back to [fallback].
  ///
  /// NOTE: `String.fromEnvironment` is intentionally NOT used here. It only
  /// accepts a *const* key argument, so calling it with a runtime [key] is a
  /// no-op on native and a hard runtime crash on web (dart2js throws
  /// "String.fromEnvironment can only be used as a const constructor").
  /// Compile-time `--dart-define` overrides are wired explicitly in
  /// [_defineOverride] below for the keys that need them.
  static String _read(String key, String fallback) {
    final fromDefine = _defineOverride(key);
    if (fromDefine != null && fromDefine.isNotEmpty) return fromDefine;

    // dotenv.maybeGet throws if load() never ran; guard so config access
    // can never crash the app.
    try {
      final fromEnv = dotenv.maybeGet(key);
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    } catch (_) {
      // dotenv not initialized; fall through to default.
    }

    return fallback;
  }

  /// Compile-time `--dart-define` overrides. Each `fromEnvironment` MUST take
  /// a const literal key (that's the whole point — it's resolved at build
  /// time), so we map the supported keys one-by-one. An unset define yields
  /// an empty string, which the caller treats as "not provided".
  static String? _defineOverride(String key) {
    switch (key) {
      case 'API_BASE_URL':
        const v = String.fromEnvironment('API_BASE_URL');
        return v.isEmpty ? null : v;
      case 'WEB_BASE_URL':
        const v = String.fromEnvironment('WEB_BASE_URL');
        return v.isEmpty ? null : v;
      case 'JWT_SECRET':
        const v = String.fromEnvironment('JWT_SECRET');
        return v.isEmpty ? null : v;
      case 'ENVIRONMENT':
        const v = String.fromEnvironment('ENVIRONMENT');
        return v.isEmpty ? null : v;
      default:
        return null;
    }
  }

  static String get baseUrl => _read('API_BASE_URL', 'http://127.0.0.1:5000');

  /// Public web app origin — used for client-facing share links
  /// (e.g. the self-booking page at `<webBaseUrl>/book/<token>`).
  ///
  /// When `WEB_BASE_URL` is not explicitly provided (the common case — the
  /// build scripts only ever set `API_BASE_URL`), we DERIVE it from the API
  /// base instead of falling back to a useless `127.0.0.1:3000`, which made
  /// every shared self-booking link dead on the client's phone ("link যায় না").
  /// The deployed topology is `api.<domain>` ↔ `app.<domain>`, so we swap a
  /// leading `api.` host segment for `app.`. A localhost API keeps the
  /// localhost web default (dev machine runs both).
  static String get webBaseUrl {
    final explicit = _read('WEB_BASE_URL', '');
    if (explicit.isNotEmpty) return explicit;
    return _deriveWebBaseFromApi(baseUrl);
  }

  /// Derives the public web origin from the API [apiBase]. `https://api.x.com`
  /// → `https://app.x.com`; a bare host with no `api.` prefix is returned as
  /// its own origin; a localhost/loopback API yields the localhost web app.
  static String _deriveWebBaseFromApi(String apiBase) {
    final uri = Uri.tryParse(apiBase);
    if (uri == null || uri.host.isEmpty) return 'http://127.0.0.1:3000';

    final host = uri.host;
    final isLocal =
        host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
    if (isLocal) return 'http://127.0.0.1:3000';

    final webHost = host.startsWith('api.')
        ? 'app.${host.substring(4)}'
        : host;
    final origin = StringBuffer('${uri.scheme}://$webHost');
    if (uri.hasPort) origin.write(':${uri.port}');
    return origin.toString();
  }

  static String get jwtSecret => _read('JWT_SECRET', '');

  static String get environment => _read('ENVIRONMENT', 'development');

  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration sessionRestoreTimeout = Duration(seconds: 10);

  static const String appName = 'GRAPHY7';
  static const String companyName = 'waLidu Tech';
  static const String appVersionLabel = 'v3.8';

  /// Numeric build number — MUST match the `+NN` in pubspec.yaml `version:`.
  /// The OTA update check compares this against the server's versionCode.
  /// Bump it on every release you publish to the landing-site APK.
  static const int appVersionCode = 39;
}
