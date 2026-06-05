// lib/features/onboarding/application/onboarding_controller.dart
//
// Owns the `onboarding_complete` flag persisted in KvStore. Splash and the
// onboarding flow read from `onboardingCompleteProvider`; the final slide
// (or Skip) calls `markComplete()` to flip the flag.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';

class OnboardingController {
  OnboardingController(this._kv);
  final KvStore _kv;

  Future<bool> isComplete() async =>
      (await _kv.readBool(KvKeys.onboardingComplete)) ?? false;

  Future<void> markComplete() => _kv.writeBool(KvKeys.onboardingComplete, true);
}

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(ref.read(kvStoreProvider)),
);

final onboardingCompleteProvider = FutureProvider<bool>(
  (ref) => ref.read(onboardingControllerProvider).isComplete(),
);
