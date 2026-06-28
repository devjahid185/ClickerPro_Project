// lib/theme/app_theme_mode.dart
//
// Clicker Pro v15 — Theme mode manager
// Two themes: Sunset Studio (default) and Sunrise Pulse.
// Deep Ocean retired in v15.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// v15: only two named themes. No generic light/dark/system enum.
enum AppThemeMode {
  sunsetStudio, // warm, editorial — default
  sunrisePulse, // bold, high-contrast, punchy
}

class ThemeModeController extends AsyncNotifier<AppThemeMode> {
  static const _kvKey = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final raw = await ref.read(kvStoreProvider).readString(_kvKey);
    return AppThemeMode.values.asNameMap()[raw] ?? AppThemeMode.sunsetStudio;
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

/// Resolves to a Flutter ThemeMode. Sunset Studio = light surfaces,
/// Sunrise Pulse = dark surfaces. Both are always explicit — no system follow.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref
      .watch(themeModeControllerProvider)
      .maybeWhen(data: (m) => m, orElse: () => AppThemeMode.sunsetStudio);
  switch (mode) {
    case AppThemeMode.sunsetStudio:
      return ThemeMode.light;
    case AppThemeMode.sunrisePulse:
      return ThemeMode.dark;
  }
});
