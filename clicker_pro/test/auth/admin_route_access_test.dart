import 'dart:async';

import 'package:clicker_pro/app.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/core/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/storage/secure_store.dart';
import 'package:clicker_pro/features/auth/domain/auth_repository.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'stub_user_repository.dart';

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
    String? email,
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
  testWidgets('Admin panel route is reachable for webAdmin users', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final secureStore = SecureStore();

    final adminUser = UserModel(
      id: 'admin-1',
      name: 'Admin User',
      email: 'admin@clickerpro.app',
      role: UserRole.webAdmin,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secureStoreProvider.overrideWithValue(secureStore),
          authRepositoryProvider.overrideWithValue(_StubAuthRepo()),
          userRepositoryProvider.overrideWithValue(
            StubUserRepository(adminUser),
          ),
        ],
        child: const ClickerProApp(),
      ),
    );

    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(RouteNames.adminPanel);
    await tester.pumpAndSettle();

    expect(find.text('Admin Panel'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Team & Staff'), findsOneWidget);

    await db.close();
  });

  testWidgets(
    'Admin panel route is denied for users without financial access',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final secureStore = SecureStore();

      final freelancerUser = UserModel(
        id: 'freelancer-1',
        name: 'Freelancer User',
        email: 'freelancer@clickerpro.app',
        role: UserRole.freelancer,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            secureStoreProvider.overrideWithValue(secureStore),
            authRepositoryProvider.overrideWithValue(_StubAuthRepo()),
            userRepositoryProvider.overrideWithValue(
              StubUserRepository(freelancerUser),
            ),
          ],
          child: const ClickerProApp(),
        ),
      );

      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(RouteNames.adminPanel);
      await tester.pumpAndSettle();

      expect(find.text('Not available for your role'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Bookings'), findsNothing);

      await db.close();
    },
  );
}
