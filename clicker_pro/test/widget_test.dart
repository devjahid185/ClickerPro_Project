// Smoke test for ClickerProApp.
//
// Real feature tests live under test/features/* and test/core/*.
// This file just confirms the app boots without throwing.
//
// We override `appDatabaseProvider` with an in-memory Drift instance so
// the boot path does not touch the platform's native sqlite (which would
// schedule a background timer that the test framework rejects).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clicker_pro/app.dart';
import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/core/storage/secure_store.dart';
import 'package:clicker_pro/features/auth/domain/auth_repository.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';

/// Stub auth repo that returns null session (no token).
class _StubAuthRepo implements AuthRepository {
  @override
  Future<Session?> restoreSession() async => null;
  @override
  Future<Session> login({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<Session> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required dynamic role,
    String? companyName,
  }) => throw UnimplementedError();
  @override
  Future<void> requestOtp({
    required String identifier,
    required dynamic purpose,
  }) => throw UnimplementedError();
  @override
  Future<Session> verifyOtp({
    required String identifier,
    required String code,
    required dynamic purpose,
  }) => throw UnimplementedError();
  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();
  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => throw UnimplementedError();
  @override
  Future<Session> acceptInvite({
    required String code,
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<Session> loginWithGoogle({required String idToken}) =>
      throw UnimplementedError();
  @override
  Future<Session> loginWithApple({required String identityToken}) =>
      throw UnimplementedError();
  @override
  Future<UserModel> changeRole(dynamic newRole) => throw UnimplementedError();
  @override
  Future<DateTime> requestDeleteAccount() => throw UnimplementedError();
  @override
  Future<void> cancelDeleteAccount() => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Stream<void> get forceLogoutSignal => const Stream<void>.empty();
}

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('ClickerProApp boots without throwing', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final secureStore = SecureStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secureStoreProvider.overrideWithValue(secureStore),
          authRepositoryProvider.overrideWithValue(_StubAuthRepo()),
        ],
        child: const ClickerProApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MaterialApp), findsOneWidget);

    await db.close();
  });
}
