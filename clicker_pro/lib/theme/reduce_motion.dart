// lib/theme/reduce_motion.dart
//
// Reduce-motion preference. When on, the app drops staggered entrances and
// press-scale micro-interactions — the escape hatch for low-RAM / low-end
// phones where animations jank. Persisted via KvStore (SharedPreferences).
//
// app.dart folds this into the MediaQuery `disableAnimations` flag, so every
// motion primitive that already honours the OS "remove animations" setting
// also honours this manual toggle.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/storage/kv_store.dart';

class ReduceMotionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return await ref.read(kvStoreProvider).readBool(KvKeys.reduceMotion) ??
        false;
  }

  Future<void> setReduceMotion(bool value) async {
    state = const AsyncLoading();
    await ref.read(kvStoreProvider).writeBool(KvKeys.reduceMotion, value);
    state = AsyncData(value);
  }
}

final reduceMotionControllerProvider =
    AsyncNotifierProvider<ReduceMotionController, bool>(
      ReduceMotionController.new,
    );

/// Resolved flag for MaterialApp's MediaQuery override. Defaults to false
/// (animations on) while the preference is still loading.
final reduceMotionProvider = Provider<bool>((ref) {
  return ref
      .watch(reduceMotionControllerProvider)
      .maybeWhen(data: (v) => v, orElse: () => false);
});
