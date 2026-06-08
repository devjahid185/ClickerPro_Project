// lib/features/auth/data/auth_api.dart

import '../../../core/network/api_client.dart';
import '../domain/otp_purpose.dart';
import '../domain/user_role.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<({String token, Map<String, dynamic> user})> login(
    String email,
    String password,
  ) async {
    final r =
        await _client.post(
              '/api/auth/login',
              body: {'email': email, 'password': password},
              authenticated: false,
            )
            as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<({String token, Map<String, dynamic> user})> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  }) async {
    final r =
        await _client.post(
              '/api/auth/register',
              // Send both `fullName` (what some backends expect) and `name`
              // (legacy / other backends) so either schema validates cleanly.
              body: {
                'fullName': name,
                'name': name,
                'email': email,
                'phone': phone,
                'password': password,
                'role': role.wireName,
                if (companyName != null && companyName.trim().isNotEmpty)
                  'companyName': companyName.trim(),
                if (companyName != null && companyName.trim().isNotEmpty)
                  'businessName': companyName.trim(),
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _client.get('/api/profile') as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> patchProfile(
    Map<String, dynamic> partial,
  ) async {
    final r =
        await _client.patch('/api/profile', body: partial)
            as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<void> requestOtp({
    required String identifier,
    required OtpPurpose purpose,
  }) async {
    await _client.post(
      '/api/auth/otp/request',
      body: {'identifier': identifier, 'purpose': purpose.wireName},
      authenticated: false,
    );
  }

  Future<({String token, Map<String, dynamic> user})> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  }) async {
    final r =
        await _client.post(
              '/api/auth/otp/verify',
              body: {
                'identifier': identifier,
                'code': code,
                'purpose': purpose.wireName,
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/api/auth/forgot',
      body: {'email': email},
      authenticated: false,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/reset',
      body: {'token': token, 'newPassword': newPassword},
      authenticated: false,
    );
  }

  Future<({String token, Map<String, dynamic> user})> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) async {
    final r =
        await _client.post(
              '/api/auth/accept-invite',
              body: {
                'code': code,
                'name': name,
                'email': email,
                'password': password,
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Map<String, dynamic>> changeRole(UserRole newRole) async {
    final r =
        await _client.post(
              '/api/profile/role',
              body: {'newRole': newRole.wireName},
            )
            as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<DateTime> requestDeleteAccount() async {
    final r =
        await _client.post('/api/account/delete-request')
            as Map<String, dynamic>;
    return DateTime.parse(r['deletedAt'] as String);
  }

  Future<Map<String, dynamic>> cancelDeleteAccount() async {
    final r =
        await _client.post('/api/account/cancel-delete')
            as Map<String, dynamic>;
    return (r['user'] as Map).cast<String, dynamic>();
  }

  Future<String> requestDataExport() async {
    final r = await _client.post('/api/account/export') as Map<String, dynamic>;
    return r['downloadUrl'] as String;
  }

  Future<({String token, Map<String, dynamic> user})> loginWithGoogle(
    String idToken,
  ) async {
    final r = await _client.post(
      '/api/auth/google',
      body: {'idToken': idToken},
      authenticated: false,
    ) as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<({String token, Map<String, dynamic> user})> loginWithApple(
    String identityToken,
  ) async {
    final r = await _client.post(
      '/api/auth/apple',
      body: {'identityToken': identityToken},
      authenticated: false,
    ) as Map<String, dynamic>;
    return (
      token: r['token'] as String,
      user: (r['user'] as Map).cast<String, dynamic>(),
    );
  }
}
