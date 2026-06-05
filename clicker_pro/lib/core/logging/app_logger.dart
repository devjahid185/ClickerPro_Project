// lib/core/logging/app_logger.dart
//
// Replaces every direct print() call. In release builds, debug logs are silenced
// via kDebugMode guard. Errors with stack traces are surfaced through debugPrint
// so they appear in flutter logs / IDE consoles.

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void i(String tag, String message) {
    if (kDebugMode) debugPrint('ℹ️  [$tag] $message');
  }

  static void w(String tag, String message) {
    if (kDebugMode) debugPrint('⚠️  [$tag] $message');
  }

  static void e(String tag, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔥 [$tag] $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }
}
