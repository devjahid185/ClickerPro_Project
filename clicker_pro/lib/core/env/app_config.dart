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
  static String get webBaseUrl =>
      _read('WEB_BASE_URL', 'http://127.0.0.1:3000');

  static String get jwtSecret => _read('JWT_SECRET', '');

  static String get environment => _read('ENVIRONMENT', 'development');

  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration sessionRestoreTimeout = Duration(seconds: 10);

  static const String appName = 'CLICKER PRO';
  static const String companyName = 'waLidu Tech';
  static const String appVersionLabel = 'v3.8';

  /// Numeric build number — MUST match the `+NN` in pubspec.yaml `version:`.
  /// The OTA update check compares this against the server's versionCode.
  /// Bump it on every release you publish to the landing-site APK.
  static const int appVersionCode = 39;
}
