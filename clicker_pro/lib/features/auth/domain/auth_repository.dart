// lib/features/auth/domain/auth_repository.dart

import '../../profile/domain/user_model.dart';
import 'otp_purpose.dart';
import 'session.dart';
import 'user_role.dart';

abstract class AuthRepository {
  Future<Session> login({required String email, required String password});

  Future<Session> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  });

  Future<void> requestOtp({
    required String identifier,
    required OtpPurpose purpose,
  });

  Future<Session> verifyOtp({
    required String identifier,
    required String code,
    required OtpPurpose purpose,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    String? email,
  });

  Future<Session> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  });

  Future<Session> loginWithGoogle({required String idToken});
  Future<Session> loginWithApple({required String identityToken});

  Future<UserModel> changeRole(UserRole newRole);

  Future<DateTime> requestDeleteAccount();
  Future<void> cancelDeleteAccount();

  Future<void> logout();
  Future<Session?> restoreSession();

  /// Emits a single event whenever any authenticated call gets a 401.
  /// SessionController subscribes to this to flip state to unauthenticated.
  Stream<void> get forceLogoutSignal;
}
