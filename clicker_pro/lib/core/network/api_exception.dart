// lib/core/network/api_exception.dart
//
// Structured exception emitted by ApiClient for any non-2xx response or
// transport-level failure. Callers catch this and surface user-facing errors.

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
    this.cause,
  });

  /// HTTP status code, or 0 for transport-level failures (no response received).
  final int statusCode;
  final String message;
  final String? body;
  final Object? cause;

  /// A 403 the backend tags with `ACCOUNT_SUSPENDED` (EnsureActive middleware)
  /// — the account was suspended mid-session. Treated like an auth failure so
  /// the app logs the user out instead of leaving them on stale cached data.
  bool get isSuspended =>
      statusCode == 403 && (body?.contains('ACCOUNT_SUSPENDED') ?? false);

  /// True for a plain 401 or a mid-session suspension — both must force logout.
  bool get isUnauthorized => statusCode == 401 || isSuspended;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}
