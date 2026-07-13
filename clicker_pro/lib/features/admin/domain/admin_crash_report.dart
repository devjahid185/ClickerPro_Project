// lib/features/admin/domain/admin_crash_report.dart
//
// Admin-side view of one crash/bug report. Maps 1:1 onto
// CrashReportController::row() (camelCase). Reports come from every surface —
// mobile, Flutter web, and the landing page — tagged by [platform].

class AdminCrashReport {
  const AdminCrashReport({
    required this.id,
    required this.error,
    required this.platform,
    required this.resolved,
    this.stackTrace,
    this.breadcrumbs = const [],
    this.appVersion,
    this.userRole,
    this.userName,
    this.userEmail,
    this.resolvedAt,
    this.createdAt,
  });

  final String id;
  final String error;

  /// 'android' | 'ios' | 'web' | 'landing' | null. Drives the platform badge.
  final String platform;
  final bool resolved;
  final String? stackTrace;

  /// Recent navigation/action trail before the crash — the "what led here".
  final List<CrashBreadcrumbView> breadcrumbs;
  final String? appVersion;
  final String? userRole;
  final String? userName;
  final String? userEmail;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  /// Who hit the crash, best-effort: name, else email, else the role, else a
  /// generic label for anonymous (pre-login / landing) reports.
  String get who => userName ?? userEmail ?? userRole ?? 'Anonymous';

  factory AdminCrashReport.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    final rawCrumbs = json['breadcrumbs'];
    final crumbs = <CrashBreadcrumbView>[];
    if (rawCrumbs is List) {
      for (final c in rawCrumbs) {
        if (c is Map) {
          crumbs.add(CrashBreadcrumbView.fromJson(c.cast<String, dynamic>()));
        }
      }
    }

    return AdminCrashReport(
      id: (json['id'] ?? '').toString(),
      error: (json['error'] ?? '').toString(),
      platform: (json['platform'] ?? 'unknown').toString(),
      resolved: json['resolved'] == true,
      stackTrace: s(json['stackTrace']),
      breadcrumbs: crumbs,
      appVersion: s(json['appVersion']),
      userRole: s(json['userRole']),
      userName: s(json['userName']),
      userEmail: s(json['userEmail']),
      resolvedAt: DateTime.tryParse((json['resolvedAt'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class CrashBreadcrumbView {
  const CrashBreadcrumbView({required this.message, this.category, this.timestamp});

  final String message;
  final String? category;
  final DateTime? timestamp;

  factory CrashBreadcrumbView.fromJson(Map<String, dynamic> json) {
    return CrashBreadcrumbView(
      message: (json['message'] ?? '').toString(),
      category: json['category']?.toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
    );
  }
}
