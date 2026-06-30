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

/// Resolves to a Flutter ThemeMode. Both Sunset Studio (warm cream) and
/// Sunrise Pulse (bright white) are LIGHT themes — there is no dark mode in
/// v15. Sunset Studio uses MaterialApp.theme; Sunrise Pulse is selected via
/// ThemeMode.dark only as the slot that maps to AppTheme.sunrisePulse(), which
/// is itself a light theme. Keeping the two distinct slots lets the app switch
/// between the two palettes through Flutter's theme/darkTheme channels.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref
      .watch(themeModeControllerProvider)
      .maybeWhen(data: (m) => m, orElse: () => AppThemeMode.sunsetStudio);
  switch (mode) {
    case AppThemeMode.sunsetStudio:
      return ThemeMode.light;
    case AppThemeMode.sunrisePulse:
      // Routed through the darkTheme slot, but AppTheme.sunrisePulse() is a
      // light theme — see app.dart.
      return ThemeMode.dark;
  }
});
