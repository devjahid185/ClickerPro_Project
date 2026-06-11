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

  /// Reads [key] from a --dart-define first (for production builds), then
  /// from the loaded .env file, then falls back to [fallback].
  static String _read(String key, String fallback) {
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;

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
}
