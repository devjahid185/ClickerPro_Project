// lib/features/auth/application/session_controller.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers.dart';
import '../../bookings/application/booking_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../freelancer/application/fl_earning_providers.dart';
import '../../invoice/application/invoice_providers.dart';
import '../../team/application/team_providers.dart';
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

    final session = await repo.restoreSession();
    if (session != null) _syncStudioDataInBackground();
    return session;
  }

  /// Pulls bookings + clients + packages from the server without blocking
  /// the caller. This is the ONLY place bookings created on another device
  /// (the web app, admin panel, teammate's phone) get pulled onto this
  /// device — without it they stay invisible until the user manually
  /// pulls-to-refresh the booking list. Fires on cold start (session
  /// restore) and after every successful login/verify/invite-accept below.
  void _syncStudioDataInBackground() {
    Future<void>(() async {
      try {
        await Future.wait([
          ref.read(bookingRepositoryProvider).refreshFromRemote(),
          ref.read(clientRepositoryProvider).refreshFromRemote(),
          ref.read(packageRepositoryProvider).refreshFromRemote(),
        ]);
      } catch (e, st) {
        // Best-effort — cached local data stays authoritative until the
        // next successful sync (pull-to-refresh, reconnect, next launch).
        AppLogger.w('session', 'background studio sync failed: $e');
        AppLogger.e('session', e, st);
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
    if (state.hasValue && state.value != null) _syncStudioDataInBackground();
  }

  /// Registers a new account. Does NOT log the user in — registration no longer
  /// yields a session; the email OTP (verifyOtp, signup) does. So this leaves
  /// the session state untouched (still null/unauthenticated) and simply
  /// surfaces any error to the caller, which then routes to the OTP screen.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? companyName,
  }) async {
    await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          phone: phone,
          password: password,
          role: role,
          companyName: companyName,
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
    if (state.hasValue && state.value != null) _syncStudioDataInBackground();
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
    if (state.hasValue && state.value != null) _syncStudioDataInBackground();
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .loginWithGoogle(idToken: idToken),
    );
    if (state.hasValue && state.value != null) _syncStudioDataInBackground();
  }

  Future<void> loginWithApple(String identityToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .loginWithApple(identityToken: identityToken),
    );
    if (state.hasValue && state.value != null) _syncStudioDataInBackground();
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
    // A role switch changes which data the user is allowed to see (owner
    // bookings vs freelancer earnings, team, finance, dues…). The cached
    // providers still hold the OLD role's data until something refetches —
    // that stale data is the "আগের রোলের ডাটা থেকে যায়" bug. Invalidate the
    // role-scoped data providers so each refetches for the new role.
    _invalidateRoleScopedData();
  }

  /// Drops cached, role-dependent data so it refetches under the new role.
  /// `currentUserProvider` / `rolePolicyProvider` update on their own (they
  /// stream the persisted user), so they're not listed here.
  void _invalidateRoleScopedData() {
    ref.invalidate(bookingListProvider);
    ref.invalidate(bookingListAllProvider);
    ref.invalidate(dashboardMetricsProvider);
    ref.invalidate(dueBreakdownProvider);
    ref.invalidate(teamMembersProvider);
    ref.invalidate(flEarningOverviewControllerProvider);
    ref.invalidate(invoiceListControllerProvider);
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
