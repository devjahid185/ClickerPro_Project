// lib/features/auth/data/auth_repository_impl.dart

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/env/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_store.dart';
import '../../profile/domain/user_model.dart';
import '../domain/auth_repository.dart';
import '../domain/otp_purpose.dart';
import '../domain/session.dart';
import '../domain/user_role.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi api,
    required AppDatabase db,
    required SecureStore secureStore,
  }) : _api = api,
       _db = db,
       _secure = secureStore;

  final AuthApi _api;
  final AppDatabase _db;
  final SecureStore _secure;

  final _forceLogout = StreamController<void>.broadcast();

  @override
  Stream<void> get forceLogoutSignal => _forceLogout.stream;

  UsersDao get _users => _db.usersDao;

  Future<Session> _persistSession(
    String token,
    Map<String, dynamic> userJson,
  ) async {
    await _secure.writeToken(token);
    final user = await _mergeWithCachedProfile(UserModel.fromJson(userJson));
    await _users.upsertCurrent(_userCompanion(user));
    return Session(token: token, user: user, issuedAt: DateTime.now());
  }

  /// The server only persists a subset of the profile (name/phone/bio/
  /// business_name/avatar). Blindly upserting its copy used to NULL out
  /// every device-side field (whatsapp, bkash, address, specialization,
  /// signature, logo…) on each login/refresh — the "profile save
  /// disappears" bug. Server wins where it has data; the local cache
  /// fills everything it doesn't know about.
  Future<UserModel> _mergeWithCachedProfile(UserModel server) async {
    final row = await _users.getCurrent();
    if (row == null) return server;
    return server.copyWith(
      whatsapp: server.whatsapp ?? row.whatsapp,
      specialization: server.specialization ?? row.specialization,
      vatBin: server.vatBin ?? row.vatBin,
      studioAddress: server.studioAddress ?? row.studioAddress,
      bkash: server.bkash ?? row.bkash,
      bankDetails: server.bankDetails ?? row.bankDetails,
      signatureUrl: server.signatureUrl ?? row.signatureUrl,
      logoUrl: server.logoUrl ?? row.logoUrl,
      avatarUrl: server.avatarUrl ?? row.avatarUrl,
      phone: server.phone ?? row.phone,
      bio: server.bio ?? row.bio,
      companyName: server.companyName ?? row.companyName,
    );
  }

  UsersTableCompanion _userCompanion(UserModel u) {
    return UsersTableCompanion(
      id: Value(
        u.id.isEmpty
            ? (u.remoteId ?? DateTime.now().microsecondsSinceEpoch.toString())
            : u.id,
      ),
      remoteId: Value(u.remoteId),
      name: Value(u.name),
      email: Value(u.email),
      phone: Value(u.phone),
      role: Value(u.role.wireName),
      ownerId: Value(u.ownerId),
      avatarUrl: Value(u.avatarUrl),
      bio: Value(u.bio),
      specialization: Value(u.specialization),
      vatBin: Value(u.vatBin),
      studioAddress: Value(u.studioAddress),
      whatsapp: Value(u.whatsapp),
      bkash: Value(u.bkash),
      bankDetails: Value(u.bankDetails),
      signatureUrl: Value(u.signatureUrl),
      logoUrl: Value(u.logoUrl),
      companyName: Value(u.companyName),
      deletedAt: Value(u.deletedAt),
      pending: const Value(false),
      updatedAt: Value(DateTime.now()),
    );
  }

  T _maybeRaise<T>(Object error) {
    if (error is ApiException && error.isUnauthorized) {
      _forceLogout.add(null);
    }
    throw error;
  }

  /// The offline "demo mode" (accept-any-credentials fallback + demo OTP
  /// 123456) is a development convenience ONLY. In a shipped build it would
  /// be a login bypass — anyone with the device could enter the app with
  /// made-up credentials in airplane mode and the OTP "123456" would pass.
  ///
  /// It is hard-gated TWO ways: it never runs in a release build
  /// (`kReleaseMode`), AND it requires a non-production ENVIRONMENT. The
  /// release-mode guard is the safety net — even if .env is missing or
  /// misconfigured, the demo path stays off in every APK/AAB Heaven ships.
  bool get _allowOfflineDemo =>
      !kReleaseMode && AppConfig.environment.toLowerCase() != 'production';

  /// Wraps a non-API failure (transport, parsing) into a clean
  /// [ApiException] for the UI instead of leaking raw error text.
  Never _raiseUnreachable(Object cause) {
    throw ApiException(
      statusCode: 0,
      message: 'Cannot reach the server. Check your internet connection.',
      cause: cause,
    );
  }

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    try {
      final r = await _api.login(email, password);
      return _persistSession(r.token, r.user);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Network unreachable. In production this is a hard failure; the
      // offline demo session is a dev-only convenience (see _allowOfflineDemo).
      if (!_allowOfflineDemo) _raiseUnreachable(e);
      final demoUser = UserModel(
        id: 'demo_${email.hashCode.abs()}',
        name: email.split('@').first,
        email: email,
        role: UserRole.owner,
      );
      return _persistSession(_demoToken, {
        'id': demoUser.id,
        'name': demoUser.name,
        'email': demoUser.email,
        'role': UserRole.owner.wireName,
        'remoteId': null,
      });
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  }) async {
    if (role == UserRole.manager) {
      throw ApiException(
        statusCode: 400,
        message:
            'Manager role cannot self-register; use the Accept Invite flow.',
      );
    }
    // Create the account but DO NOT persist a session — the backend issues no
    // token here. The user must complete the email OTP (verifyOtp, signup),
    // which is what mints the token and logs them in. This is the fix for
    // "registering logged me in without OTP, and reopening the app stayed
    // logged in": no token is ever stored until OTP succeeds.
    try {
      await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        companyName: companyName,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (!_allowOfflineDemo) _raiseUnreachable(e);
      // Dev-only offline: nothing to persist; the OTP screen's demo path
      // (code 123456) will create the local session on verify.
    }
  }

  /// Demo OTP accepted offline when the backend is unreachable.
  static const _demoOtp = '123456';
  static const _demoToken = 'demo_offline_token';

  @override
  Future<void> requestOtp({
    required String identifier,
    required OtpPurpose purpose,
  }) async {
    try {
      await _api.requestOtp(identifier: identifier, purpose: purpose);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Network unreachable — dev builds silently succeed so the OTP
      // screen appears (user enters $_demoOtp); production surfaces it.
      if (!_allowOfflineDemo) _raiseUnreachable(e);
    }
  }

  @override
  Future<Session> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  }) async {
    try {
      final r = await _api.verifyOtp(
        identifier: identifier,
        code: code,
        purpose: purpose,
      );
      final token = r.token;
      final user = r.user;
      if (token != null && user != null) {
        return _persistSession(token, user);
      }
      // The Laravel verify endpoint confirms the code but does not issue
      // a token. If a session already exists (e.g. OTP after register),
      // keep it; otherwise the caller must route the user to login.
      final existingToken = await _secure.readToken();
      final row = await _users.getCurrent();
      if (existingToken != null && row != null) {
        return Session(
          token: existingToken,
          user: UserModel(
            id: row.id,
            name: row.name,
            email: row.email,
            role: UserRole.fromString(row.role),
            remoteId: row.remoteId,
            phone: row.phone,
            ownerId: row.ownerId,
          ),
          issuedAt: DateTime.now(),
        );
      }
      throw ApiException(
        statusCode: 401,
        message: 'Code verified. Please log in with your password.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      // Network unreachable — dev builds accept the demo code.
      if (!_allowOfflineDemo) _raiseUnreachable(e);
      if (code.trim() != _demoOtp) {
        throw ApiException(
          statusCode: 400,
          message: 'Code is invalid or expired. Try again or resend.',
        );
      }
      // Build a local demo user from the identifier.
      final demoUser = UserModel(
        id: 'demo_${identifier.hashCode.abs()}',
        name: identifier.contains('@')
            ? identifier.split('@').first
            : identifier,
        email: identifier.contains('@') ? identifier : '$identifier@demo.local',
        role: UserRole.owner,
        phone: identifier.contains('@') ? null : identifier,
      );
      return _persistSession(_demoToken, {
        'id': demoUser.id,
        'name': demoUser.name,
        'email': demoUser.email,
        'role': UserRole.owner.wireName,
        'remoteId': null,
        'phone': demoUser.phone,
      });
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _api.forgotPassword(email);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Network unreachable — dev builds silently succeed (demo OTP path);
      // production surfaces the failure.
      if (!_allowOfflineDemo) _raiseUnreachable(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    String? email,
  }) => _api.resetPassword(
    token: token,
    newPassword: newPassword,
    email: email,
  );

  @override
  Future<Session> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) async {
    final r = await _api.acceptInvite(
      code: code,
      name: name,
      email: email,
      password: password,
    );
    return _persistSession(r.token, r.user);
  }

  @override
  Future<Session> loginWithGoogle({required String idToken}) async {
    final r = await _api.loginWithGoogle(idToken);
    return _persistSession(r.token, r.user);
  }

  @override
  Future<Session> loginWithApple({required String identityToken}) async {
    final r = await _api.loginWithApple(identityToken);
    return _persistSession(r.token, r.user);
  }

  @override
  Future<UserModel> changeRole(UserRole newRole) async {
    try {
      final json = await _api.changeRole(newRole);
      final updated = UserModel.fromJson(json);
      await _users.upsertCurrent(_userCompanion(updated));
      return updated;
    } catch (e) {
      return _maybeRaise<UserModel>(e);
    }
  }

  @override
  Future<DateTime> requestDeleteAccount() async {
    try {
      final at = await _api.requestDeleteAccount();
      final current = await _users.getCurrent();
      if (current != null) {
        await _users.updateDeletedAt(current.id, at);
      }
      return at;
    } catch (e) {
      return _maybeRaise<DateTime>(e);
    }
  }

  @override
  Future<void> cancelDeleteAccount() async {
    try {
      await _api.cancelDeleteAccount();
      final current = await _users.getCurrent();
      if (current != null) {
        await _users.updateDeletedAt(current.id, null);
      }
    } catch (e) {
      _maybeRaise<void>(e);
    }
  }

  @override
  Future<void> logout() async {
    await _secure.clearToken();
    await _users.clearAll();
    // Outbox is preserved across logout per Requirement 6.11.
  }

  @override
  Future<Session?> restoreSession() async {
    final token = await _secure.readToken();
    if (token == null) return null;

    // Demo / offline session — restore directly from local DB without a
    // network round-trip.
    if (token == _demoToken) {
      final row = await _users.getCurrent();
      if (row == null) return null;
      final user = UserModel(
        id: row.id,
        name: row.name,
        email: row.email,
        role: UserRole.fromString(row.role),
        remoteId: row.remoteId,
        phone: row.phone,
        avatarUrl: row.avatarUrl,
        bio: row.bio,
        specialization: row.specialization,
        whatsapp: row.whatsapp,
        bkash: row.bkash,
        bankDetails: row.bankDetails,
        signatureUrl: row.signatureUrl,
        logoUrl: row.logoUrl,
        companyName: row.companyName,
        ownerId: row.ownerId,
      );
      return Session(token: token, user: user, issuedAt: DateTime.now());
    }

    // OFFLINE-FIRST RESTORE: a stored token + cached user = logged in,
    // instantly. The old order (network first, behind the splash's short
    // timeout) sent users back to the login screen on any slow connection
    // — the "auto logout on reopen" bug. The server copy is refreshed in
    // the background; a 401 there clears the token and signals logout.
    final row = await _users.getCurrent();
    if (row != null) {
      final user = UserModel(
        id: row.id,
        name: row.name,
        email: row.email,
        role: UserRole.fromString(row.role),
        remoteId: row.remoteId,
        phone: row.phone,
        avatarUrl: row.avatarUrl,
        bio: row.bio,
        specialization: row.specialization,
        whatsapp: row.whatsapp,
        bkash: row.bkash,
        bankDetails: row.bankDetails,
        signatureUrl: row.signatureUrl,
        logoUrl: row.logoUrl,
        companyName: row.companyName,
        ownerId: row.ownerId,
      );
      _refreshProfileInBackground();
      return Session(token: token, user: user, issuedAt: DateTime.now());
    }

    // Token but no cached user (e.g. cleared data) — must ask the server.
    try {
      final json = await _api.getProfile();
      return _persistSession(token, json);
    } on ApiException catch (e, st) {
      AppLogger.w('auth', 'restoreSession failed: ${e.message}');
      if (e.isUnauthorized) await _secure.clearToken();
      AppLogger.e('auth', e, st);
      return null;
    } catch (e) {
      AppLogger.w('auth', 'restoreSession unreachable: $e');
      return null;
    }
  }

  /// Refreshes the cached profile from the server without blocking app
  /// start. A 401 means the token was revoked — clear it and force logout.
  void _refreshProfileInBackground() {
    Future<void>(() async {
      try {
        final json = await _api.getProfile();
        final user = await _mergeWithCachedProfile(UserModel.fromJson(json));
        await _users.upsertCurrent(_userCompanion(user));
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await _secure.clearToken();
          _forceLogout.add(null);
        }
      } catch (_) {
        // Offline — cached profile stays authoritative until next launch.
      }
    });
  }

  void dispose() => _forceLogout.close();
}
