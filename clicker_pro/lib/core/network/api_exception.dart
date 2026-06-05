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

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}
