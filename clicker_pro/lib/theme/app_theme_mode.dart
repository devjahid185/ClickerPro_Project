// lib/theme/app_theme_mode.dart
//
// Clicker Pro — Theme mode manager (MOD-64)
// Persists choice via KvStore (SharedPreferences under the hood).
// Exposes a Riverpod StateNotifier provider consumed by app.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

enum AppThemeMode { dark, light, system }

class ThemeModeController extends AsyncNotifier<AppThemeMode> {
  static const _kvKey = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final raw = await ref.read(kvStoreProvider).readString(_kvKey);
    return AppThemeMode.values.asNameMap()[raw] ?? AppThemeMode.light;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = const AsyncLoading();
    await ref.read(kvStoreProvider).writeString(_kvKey, mode.name);
    state = AsyncData(mode);
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, AppThemeMode>(
      ThemeModeController.new,
    );

/// Convenience provider that resolves the actual ThemeMode
/// for MaterialApp.themeMode based on the persisted preference.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref
      .watch(themeModeControllerProvider)
      .maybeWhen(data: (m) => m, orElse: () => AppThemeMode.light);
  switch (mode) {
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});
