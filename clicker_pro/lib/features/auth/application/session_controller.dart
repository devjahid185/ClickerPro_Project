// lib/features/auth/application/session_controller.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/domain/user_model.dart';
import '../domain/otp_purpose.dart';
import '../domain/session.dart';
import '../domain/user_role.dart';

class SessionController extends AsyncNotifier<Session?> {
  StreamSubscription<void>? _forceLogoutSub;

  @override
  Future<Session?> build() async {
    final repo = ref.read(authRepositoryProvider);

    _forceLogoutSub?.cancel();
    _forceLogoutSub = repo.forceLogoutSignal.listen((_) {
      // Any 401 from any authenticated request → unauthenticated state.
      state = const AsyncData(null);
    });
    ref.onDispose(() => _forceLogoutSub?.cancel());

    return repo.restoreSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            phone: phone,
            password: password,
            role: role,
            companyName: companyName,
          ),
    );
  }

  Future<void> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyOtp(identifier: identifier, code: code, purpose: purpose),
    );
  }

  Future<void> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .acceptInvite(
            code: code,
            name: name,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> changeRole(UserRole newRole) async {
    final updated = await ref.read(authRepositoryProvider).changeRole(newRole);
    final s = state.value;
    if (s != null) {
      state = AsyncData(
        Session(token: s.token, user: updated, issuedAt: s.issuedAt),
      );
    } else {
      state = const AsyncData(null);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> updateUser(UserModel u) async {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(Session(token: s.token, user: u, issuedAt: s.issuedAt));
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);
