// lib/features/crash_reporting/data/crash_service.dart
//
// Crash reporting service — records errors, navigation breadcrumbs,
// and user context. Sends to a crash reporting backend in production;
// currently logs locally.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
  return CrashService();
});

class CrashService {
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
    // ignore: unused_local_variable
    final report = CrashReport(
      id: _uuid.v4(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      userId: _userId,
      userRole: _userRole,
      breadcrumbs: List.unmodifiable(_breadcrumbs),
      timestamp: DateTime.now(),
    );

    // TODO: POST /api/crash-reports
    // Log locally for now
    _breadcrumbs.clear();
  }

  void reset() {
    _breadcrumbs.clear();
    _crashCount = 0;
  }
}
