// lib/features/push/application/push_token_providers.dart
//
// Riverpod wiring for the push-token feature.  This slice intentionally
// stops short of pulling in `firebase_messaging` — that's a runtime
// integration step that needs a Firebase project + iOS APNs cert + a
// platform-specific delegate setup, none of which we can land in one
// pure-Dart slice.  The pieces here form the contract:
//
//   `PushTokenRepository`   — abstraction
//   `PushTokenController`   — orchestrates `register` / `unregister`
//                             so a future FCM bootstrap can simply do
//                             `controller.registerForCurrentPlatform(token)`।

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/push_token_api.dart';
import '../data/push_token_repository_impl.dart';
import '../domain/push_token_payload.dart';
import '../domain/push_token_repository.dart';

final pushTokenApiProvider = Provider<PushTokenApi>(
  (ref) => PushTokenApi(ref.read(apiClientProvider)),
);

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => PushTokenRepositoryImpl(api: ref.read(pushTokenApiProvider)),
);

class PushTokenController {
  PushTokenController(this._repo);

  final PushTokenRepository _repo;

  /// Resolve the platform string the backend expects.  `kIsWeb` short
  /// circuits before `Platform` is touched, which would otherwise throw
  /// on web।
  String get currentPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  Future<void> registerForCurrentPlatform({
    required String token,
    String? appVersion,
    String? language,
  }) {
    return _repo.register(
      PushTokenPayload(
        token: token,
        platform: currentPlatform,
        appVersion: appVersion,
        language: language,
      ),
    );
  }

  Future<void> unregister(String token) => _repo.unregister(token);
}

final pushTokenControllerProvider = Provider<PushTokenController>(
  (ref) => PushTokenController(ref.read(pushTokenRepositoryProvider)),
);
