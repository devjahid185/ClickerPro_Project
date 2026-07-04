// lib/features/auth/data/auth_api.dart
//
// Wire-level auth/account methods against the Laravel backend.
//
// Laravel wraps every payload in `{ "data": ... }` — e.g. login returns
// `{ "data": { "token": "...", "user": {...} } }` (AuthController). The
// `_data()` helper below unwraps that envelope (tolerating flat legacy
// responses) so a contract drift can never silently break login again.

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/otp_purpose.dart';
import '../domain/user_role.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  // ─────────────────────── envelope helpers ───────────────────────

  /// Unwraps `{ data: {...} }` → inner map; tolerates flat responses.
  Map<String, dynamic> _data(dynamic r) {
    if (r is Map) {
      final d = r['data'];
      if (d is Map) return d.cast<String, dynamic>();
      return r.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  /// Extracts the `{token, user}` pair from an auth response, throwing a
  /// descriptive [ApiException] (instead of a TypeError) when the server
  /// answered 2xx but with an unexpected shape.
  ({String token, Map<String, dynamic> user}) _session(dynamic r) {
    final d = _data(r);
    final token = d['token'];
    final user = d['user'];
    if (token is! String || token.isEmpty || user is! Map) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected login response from server',
        body: r.toString(),
      );
    }
    return (token: token, user: user.cast<String, dynamic>());
  }

  /// The user payload of profile-shaped responses: `{data: user}` or
  /// legacy `{user: ...}`.
  Map<String, dynamic> _user(dynamic r) {
    final d = _data(r);
    final u = d['user'];
    if (u is Map) return u.cast<String, dynamic>();
    return d;
  }

  // ─────────────────────── auth ───────────────────────

  Future<({String token, Map<String, dynamic> user})> login(
    String email,
    String password,
  ) async {
    final r = await _client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return _session(r);
  }

  /// Registers a new account. The backend intentionally returns NO token here
  /// (`token: null`, `requiresOtp: true`) — the account is unverified until the
  /// email OTP is confirmed via [verifyOtp] (purpose=signup), which issues the
  /// token. So this returns only the user; there is no session yet.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  }) async {
    final r = await _client.post(
      '/api/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        // Laravel validates role against OWNER / FREELANCER / BOTH
        // (uppercase). Anything else is rejected with a 422.
        'role': role.serverName,
        if (companyName != null && companyName.trim().isNotEmpty)
          'business_name': companyName.trim(),
      },
      authenticated: false,
    );
    return _user(r);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _client.get('/api/profile');
    return _user(r);
  }

  Future<Map<String, dynamic>> patchProfile(
    Map<String, dynamic> partial,
  ) async {
    final r = await _client.patch('/api/profile', body: partial);
    return _user(r);
  }

  Future<void> requestOtp({
    required String identifier,
    required OtpPurpose purpose,
  }) async {
    await _client.post(
      '/api/auth/otp/request',
      // Laravel validates `email`; `identifier` kept for compatibility.
      body: {
        'email': identifier,
        'identifier': identifier,
        'purpose': purpose.wireName,
      },
      authenticated: false,
    );
  }

  /// `POST /api/auth/otp/verify`.
  ///
  /// The Laravel endpoint verifies the code and answers `{message: ok}`
  /// WITHOUT issuing a token — so `token`/`user` are nullable here and
  /// the repository decides how to proceed (keep the existing session,
  /// or route the user to login).
  Future<({String? token, Map<String, dynamic>? user})> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  }) async {
    final r = await _client.post(
      '/api/auth/otp/verify',
      body: {
        'email': identifier,
        'identifier': identifier,
        'code': code,
        'purpose': purpose.wireName,
      },
      authenticated: false,
    );
    final d = _data(r);
    final token = d['token'];
    final user = d['user'];
    return (
      token: token is String && token.isNotEmpty ? token : null,
      user: user is Map ? user.cast<String, dynamic>() : null,
    );
  }

  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/api/auth/forgot',
      body: {'email': email},
      authenticated: false,
    );
  }

  /// `POST /api/auth/reset`. Laravel requires `{email, token, password}`.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    String? email,
  }) async {
    await _client.post(
      '/api/auth/reset',
      body: {
        'token': token,
        'password': newPassword,
        'newPassword': newPassword,
        'email': ?email,
      },
      authenticated: false,
    );
  }

  Future<({String token, Map<String, dynamic> user})> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) async {
    final r = await _client.post(
      '/api/auth/accept-invite',
      body: {
        'code': code,
        'name': name,
        'email': email,
        'password': password,
      },
      authenticated: false,
    );
    return _session(r);
  }

  Future<Map<String, dynamic>> changeRole(UserRole newRole) async {
    final r = await _client.post(
      '/api/profile/role',
      body: {'newRole': newRole.serverName},
    );
    return _user(r);
  }

  // ─────────────────────── account ───────────────────────

  /// `POST /api/account/delete-request`. Laravel schedules deletion 7 days
  /// out and returns only a message — mirror that schedule locally when no
  /// timestamp is present in the response.
  Future<DateTime> requestDeleteAccount() async {
    final r = await _client.post('/api/account/delete-request');
    final d = _data(r);
    final raw = d['deletedAt'] ?? d['deleted_at'];
    return raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now().add(const Duration(days: 7)))
        : DateTime.now().add(const Duration(days: 7));
  }

  Future<void> cancelDeleteAccount() async {
    await _client.post('/api/account/cancel-delete');
  }

  Future<String> requestDataExport() async {
    final r = await _client.post('/api/account/export');
    final d = _data(r);
    final url = d['downloadUrl'] ?? d['download_url'];
    if (url is String && url.isNotEmpty) return url;
    throw ApiException(statusCode: 0, message: 'Export link missing');
  }

  // ─────────────────────── social ───────────────────────

  Future<({String token, Map<String, dynamic> user})> loginWithGoogle(
    String idToken,
  ) async {
    final r = await _client.post(
      '/api/auth/google',
      body: {'idToken': idToken},
      authenticated: false,
    );
    return _session(r);
  }

  Future<({String token, Map<String, dynamic> user})> loginWithApple(
    String identityToken,
  ) async {
    final r = await _client.post(
      '/api/auth/apple',
      body: {'identityToken': identityToken},
      authenticated: false,
    );
    return _session(r);
  }
}
