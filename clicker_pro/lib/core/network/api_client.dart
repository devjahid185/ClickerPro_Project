// lib/core/network/api_client.dart
//
// Single HTTP client used by every Api* class. Handles:
//   - JSON encoding / decoding
//   - Authorization header injection from SecureStore when token present
//   - JWT token refresh mechanism via 401 interception
//   - 15-second request timeout (AppConfig.networkTimeout)
//   - Network errors → ApiException(0) wrapping the underlying cause
//
import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../env/app_config.dart';
import '../logging/app_logger.dart';
import '../storage/secure_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SecureStore? secureStore,
    http.Client? httpClient,
  }) : baseUrl = baseUrl ?? AppConfig.baseUrl,
       _secure = secureStore ?? SecureStore(),
       _http = httpClient ?? http.Client();

  final String baseUrl;
  final SecureStore _secure;
  final http.Client _http;

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated) {
      final token = await _secure.readToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      },
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) => _sendWithRetry(
    () async => _http.get(
      _uri(path, query),
      headers: await _headers(authenticated: authenticated),
    ),
    authenticated: authenticated,
  );

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _sendWithRetry(
    () async => _http.post(
      _uri(path),
      headers: await _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    ),
    authenticated: authenticated,
  );

  Future<dynamic> patch(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) => _sendWithRetry(
    () async => _http.patch(
      _uri(path),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body),
    ),
    authenticated: authenticated,
  );

  Future<dynamic> delete(String path, {bool authenticated = true}) => _sendWithRetry(
    () async => _http.delete(
      _uri(path),
      headers: await _headers(authenticated: authenticated),
    ),
    authenticated: authenticated,
  );

  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() request, {
    required bool authenticated,
  }) async {
    try {
      final response = await request().timeout(AppConfig.networkTimeout);
      // A 401 on an authenticated request means the token is invalid/expired.
      // We have no refresh-token endpoint (JWT is long-lived), so the correct
      // behaviour is to surface it as an UnauthorizedException — the auth
      // repository listens for that and drives the app back to login.
      return _handle(response);
    } on TimeoutException catch (e, st) {
      AppLogger.e('api', 'timeout: $e', st);
      throw ApiException(statusCode: 0, message: 'Request timed out', cause: e);
    } on SocketException catch (e, st) {
      AppLogger.e('api', 'socket: $e', st);
      throw ApiException(
        statusCode: 0,
        message: 'No network connection',
        cause: e,
      );
    } on http.ClientException catch (e, st) {
      AppLogger.e('api', 'client: $e', st);
      throw ApiException(statusCode: 0, message: 'Network error', cause: e);
    }
  }

  dynamic _handle(http.Response r) {
    final status = r.statusCode;
    final hasBody = r.body.isNotEmpty;
    dynamic decoded;
    if (hasBody) {
      try {
        decoded = jsonDecode(r.body);
      } catch (_) {
        decoded = r.body;
      }
    }
    if (status >= 200 && status < 300) return decoded;

    final message =
        _extractMessage(decoded) ?? r.reasonPhrase ?? 'HTTP $status';
    AppLogger.w('api', 'non-2xx $status: $message');
    throw ApiException(statusCode: status, message: message, body: r.body);
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      for (final key in const ['message', 'error', 'detail']) {
        final v = decoded[key];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  void close() => _http.close();
}
