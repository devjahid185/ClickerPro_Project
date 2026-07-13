// lib/features/crash_reporting/data/crash_service.dart
//
// Crash reporting service — records errors, navigation breadcrumbs,
// and user context. Sends to a crash reporting backend in production;
// currently logs locally.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

const _uuid = Uuid();

/// Surface the crash happened on, so the admin console can tell a mobile crash
/// from a web one. `kIsWeb` wins because `defaultTargetPlatform` reports the
/// host OS (android/ios) even in a browser, which would mislabel web crashes.
String get _crashPlatform => kIsWeb ? 'web' : defaultTargetPlatform.name;

class CrashBreadcrumb {
  final String id;
  final String message;
  final DateTime timestamp;
  final String? category;

  const CrashBreadcrumb({
    required this.id,
    required this.message,
    required this.timestamp,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (category != null) 'category': category,
    };
  }
}

class CrashReport {
  final String id;
  final String error;
  final String stackTrace;
  final String? userId;
  final String? userRole;
  final List<CrashBreadcrumb> breadcrumbs;
  final DateTime timestamp;

  const CrashReport({
    required this.id,
    required this.error,
    required this.stackTrace,
    this.userId,
    this.userRole,
    this.breadcrumbs = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'error': error,
      'stackTrace': stackTrace,
      if (userId != null) 'userId': userId,
      if (userRole != null) 'userRole': userRole,
      'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

final crashServiceProvider = Provider<CrashService>((ref) {
  return CrashService(ref.read(apiClientProvider));
});

class CrashService {
  CrashService([this._client]);

  final ApiClient? _client;
  String? _userId;
  String? _userRole;
  final List<CrashBreadcrumb> _breadcrumbs = [];
  int _crashCount = 0;
  bool _enabled = true;

  bool get enabled => _enabled;
  int get crashCount => _crashCount;
  List<CrashBreadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  void setEnabled(bool value) {
    _enabled = value;
  }

  void setUserContext({required String userId, required String role}) {
    _userId = userId;
    _userRole = role;
  }

  void clearUserContext() {
    _userId = null;
    _userRole = null;
  }

  void recordBreadcrumb(String message, {String? category}) {
    if (!_enabled) return;
    _breadcrumbs.add(
      CrashBreadcrumb(
        id: _uuid.v4(),
        message: message,
        timestamp: DateTime.now(),
        category: category,
      ),
    );
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeAt(0);
    }
  }

  Future<void> recordError(Object error, StackTrace stackTrace) async {
    if (!_enabled) return;
    _crashCount++;
    final report = CrashReport(
      id: _uuid.v4(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      userId: _userId,
      userRole: _userRole,
      breadcrumbs: List.unmodifiable(_breadcrumbs),
      timestamp: DateTime.now(),
    );

    // Best-effort upload; never throw from the crash handler itself.
    try {
      await _client?.post('/api/crash-reports', body: {
        'error': report.error,
        'stackTrace': report.stackTrace,
        'userRole': report.userRole,
        'breadcrumbs': report.breadcrumbs.map((b) => b.toJson()).toList(),
        'platform': _crashPlatform,
      });
    } catch (_) {/* swallow — telemetry must not crash the app */}

    _breadcrumbs.clear();
  }

  void reset() {
    _breadcrumbs.clear();
    _crashCount = 0;
  }
}
