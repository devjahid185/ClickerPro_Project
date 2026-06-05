// lib/theme/theme_aware_colors.dart
//
// Clicker Pro — Theme-aware color accessor (MOD-64)
// Returns the correct palette (dark AppColors or light AppColorsLight)
// based on the current brightness. Use in widgets that need a single
// entry point regardless of active theme.

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_light.dart';

/// Accessor that delegates to the correct color palette.
class ThemeAwareColors {
  const ThemeAwareColors._(this._isDark);

  final bool _isDark;

  /// Build-time accessor from BuildContext.
  factory ThemeAwareColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ThemeAwareColors._(brightness == Brightness.dark);
  }

  bool get isDark => _isDark;

  // ── Surface ──────────────────────────────────────────────
  Color get cream => _isDark ? AppColors.voidBlack : AppColorsLight.cream;
  Color get creamDark =>
      _isDark ? AppColors.voidLight : AppColorsLight.creamDark;
  Color get voidElevated =>
      _isDark ? AppColors.voidElevated : AppColorsLight.voidElevated;

  // ── Primary (teal in dark, terracotta in light) ──────────
  Color get accent => _isDark ? AppColors.teal : AppColorsLight.terracotta;
  Color get accentLight =>
      _isDark ? AppColors.tealLight : AppColorsLight.terracottaLight;
  Color get accentSoft =>
      _isDark ? AppColors.tealSoft : AppColorsLight.terracottaSoft;

  // ── Secondary ────────────────────────────────────────────
  Color get gold => _isDark ? AppColors.gold : AppColorsLight.gold;
  Color get purple => _isDark ? AppColors.purple : AppColorsLight.plum;

  // ── Text ─────────────────────────────────────────────────
  Color get textPrimary =>
      _isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color get textSecondary =>
      _isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted =>
      _isDark ? AppColors.textMuted : AppColorsLight.textMuted;

  // ── Semantic ─────────────────────────────────────────────
  Color get success => _isDark ? AppColors.green : AppColorsLight.sage;
  Color get error => _isDark ? AppColors.red : AppColorsLight.rust;
  Color get warning => _isDark ? AppColors.yellow : AppColorsLight.yellow;

  // ── Glass ────────────────────────────────────────────────
  Color get glass => _isDark ? AppColors.glass : AppColorsLight.glass;
  Color get glassBorder =>
      _isDark ? AppColors.glassBorder : AppColorsLight.glassBorder;
  Color get hairline => _isDark ? AppColors.hairline : AppColorsLight.hairline;

  // ── Nav / Topbar ─────────────────────────────────────────
  Color get topbarBg => _isDark ? AppColors.topbarBg : AppColorsLight.topbarBg;
  Color get bottomNavBg =>
      _isDark ? AppColors.bottomNavBg : AppColorsLight.bottomNavBg;
}
