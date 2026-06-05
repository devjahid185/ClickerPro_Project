// lib/core/providers.dart
//
// Aggregated root providers. Feature-specific providers live in their feature
// folders and are imported by callers; the providers exposed here are the
// shared infrastructure that every feature depends on.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'env/app_config.dart';
import 'network/api_client.dart';
import 'storage/kv_store.dart';
import 'storage/secure_store.dart';

import '../features/auth/data/auth_api.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/team_invite_api.dart';
import '../features/auth/data/team_invite_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/team_invite_repository.dart';
import '../features/legal/data/legal_api.dart';
import '../features/legal/data/legal_repository_impl.dart';
import '../features/legal/domain/legal_repository.dart';
import '../features/profile/data/user_api.dart';
import '../features/profile/data/user_repository_impl.dart';
import '../features/profile/domain/user_repository.dart';
import '../features/settings/data/preferences_repository_impl.dart';
import '../features/settings/domain/preferences_repository.dart';

/// Single AppDatabase instance, kept alive for the app lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final kvStoreProvider = Provider<KvStore>((_) => KvStore());

final secureStoreProvider = Provider<SecureStore>(
  (ref) => SecureStore(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: AppConfig.baseUrl,
    secureStore: ref.read(secureStoreProvider),
  ),
);

/// Streams `true` while the device has network connectivity.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  bool isOnline(List<ConnectivityResult> rs) =>
      rs.any((r) => r != ConnectivityResult.none);

  final controller = StreamController<bool>();
  () async {
    final initial = await connectivity.checkConnectivity();
    if (!controller.isClosed) controller.add(isOnline(initial));
  }();

  final sub = connectivity.onConnectivityChanged.listen((rs) {
    if (!controller.isClosed) controller.add(isOnline(rs));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Feature API + Repository providers
// ---------------------------------------------------------------------------

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.read(apiClientProvider)),
);

final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.read(apiClientProvider)),
);

final legalApiProvider = Provider<LegalApi>(
  (ref) => LegalApi(ref.read(apiClientProvider)),
);

final teamInviteApiProvider = Provider<TeamInviteApi>(
  (ref) => TeamInviteApi(ref.read(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final impl = AuthRepositoryImpl(
    api: ref.read(authApiProvider),
    db: ref.read(appDatabaseProvider),
    secureStore: ref.read(secureStoreProvider),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    api: ref.read(userApiProvider),
    db: ref.read(appDatabaseProvider),
  ),
);

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepositoryImpl(
    db: ref.read(appDatabaseProvider),
    kv: ref.read(kvStoreProvider),
  ),
);

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepositoryImpl(
    api: ref.read(legalApiProvider),
    authApi: ref.read(authApiProvider),
  ),
);

final teamInviteRepositoryProvider = Provider<TeamInviteRepository>(
  (ref) => TeamInviteRepositoryImpl(ref.read(teamInviteApiProvider)),
);
