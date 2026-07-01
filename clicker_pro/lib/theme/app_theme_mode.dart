// lib/theme/app_theme_mode.dart
//
// Clicker Pro — Theme mode manager.
// Two mobile themes (both LIGHT):
//   • clickerPro   — the current default (Hanken Grotesk + #E2620E, per spec)
//   • sunsetStudio — the earlier warm editorial theme (Playfair + #FF6200)
// Web uses its own theme (see AppTheme.web()); these apply to mobile.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// The named app themes. Both are light; the app has no dark mode.
enum AppThemeMode {
  clickerPro, // DEFAULT — editorial paper, orange #E2620E, Hanken Grotesk
  sunsetStudio, // legacy — warm cream, orange #FF6200, Playfair Display
}

class ThemeModeController extends AsyncNotifier<AppThemeMode> {
  static const _kvKey = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final raw = await ref.read(kvStoreProvider).readString(_kvKey);
    return AppThemeMode.values.asNameMap()[raw] ?? AppThemeMode.clickerPro;
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

/// The active theme mode, resolved with the default fallback. Widgets and
/// app.dart read this to pick the ThemeData / palette. Both themes are light,
/// so there is no ThemeMode.dark involved — app.dart passes the resolved
/// ThemeData straight into MaterialApp.theme.
final activeThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref
      .watch(themeModeControllerProvider)
      .maybeWhen(data: (m) => m, orElse: () => AppThemeMode.clickerPro);
});
