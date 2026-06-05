// lib/features/auth/data/auth_repository_impl.dart

import 'dart:async';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/users_dao.dart';
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
    final user = UserModel.fromJson(userJson);
    await _users.upsertCurrent(_userCompanion(user));
    return Session(token: token, user: user, issuedAt: DateTime.now());
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

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final r = await _api.login(email, password);
    return _persistSession(r.token, r.user);
  }

  @override
  Future<Session> register({
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
    final r = await _api.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      companyName: companyName,
    );
    return _persistSession(r.token, r.user);
  }

  @override
  Future<void> requestOtp({
    required String identifier,
    required OtpPurpose purpose,
  }) => _api.requestOtp(identifier: identifier, purpose: purpose);

  @override
  Future<Session> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  }) async {
    final r = await _api.verifyOtp(
      identifier: identifier,
      code: code,
      purpose: purpose,
    );
    return _persistSession(r.token, r.user);
  }

  @override
  Future<void> forgotPassword({required String email}) =>
      _api.forgotPassword(email);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _api.resetPassword(token: token, newPassword: newPassword);

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
    try {
      final json = await _api.getProfile();
      return _persistSession(token, json);
    } on ApiException catch (e, st) {
      AppLogger.w('auth', 'restoreSession failed: ${e.message}');
      if (e.isUnauthorized || e.isNetwork) {
        if (e.isUnauthorized) await _secure.clearToken();
        return null;
      }
      AppLogger.e('auth', e, st);
      return null;
    }
  }

  void dispose() => _forceLogout.close();
}
