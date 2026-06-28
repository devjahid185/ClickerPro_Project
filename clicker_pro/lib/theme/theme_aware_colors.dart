// lib/theme/theme_aware_colors.dart
//
// Clicker Pro v15 — Theme-aware color accessor
// Delegates to AppColorsLight (Sunset Studio) or AppColorsPulse (Sunrise Pulse)
// based on the active theme brightness.

import 'package:flutter/material.dart';
import 'app_colors_light.dart';
import 'app_colors_pulse.dart';

class ThemeAwareColors {
  const ThemeAwareColors._(this._isDark);

  final bool _isDark;

  factory ThemeAwareColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ThemeAwareColors._(brightness == Brightness.dark);
  }

  bool get isDark => _isDark;

  // ── Surface ──────────────────────────────────────────────────
  Color get bg =>
      _isDark ? AppColorsPulse.bg : AppColorsLight.cream;
  Color get surface =>
      _isDark ? AppColorsPulse.surface : AppColorsLight.glass;
  Color get surfaceAlt =>
      _isDark ? AppColorsPulse.surfaceAlt : AppColorsLight.creamDark;
  Color get surfaceHigh =>
      _isDark ? AppColorsPulse.surfaceHigh : AppColorsLight.creamDeep;

  // Backward-compat
  Color get cream => bg;
  Color get creamDark => surfaceAlt;
  Color get voidElevated => surfaceAlt;

  // ── Primary accent ────────────────────────────────────────────
  // Sunset Studio: terracotta · Sunrise Pulse: sunrise red-orange
  Color get accent =>
      _isDark ? AppColorsPulse.primary : AppColorsLight.terracotta;
  Color get accentLight =>
      _isDark ? AppColorsPulse.primaryLight : AppColorsLight.terracottaLight;
  Color get accentSoft =>
      _isDark ? AppColorsPulse.primarySoft : AppColorsLight.terracottaSoft;
  Color get accentGlow =>
      _isDark ? AppColorsPulse.primaryGlow : AppColorsLight.terracottaGlow;

  // ── Secondary ─────────────────────────────────────────────────
  Color get gold =>
      _isDark ? AppColorsPulse.amber : AppColorsLight.gold;
  Color get purple =>
      _isDark ? AppColorsPulse.purple : AppColorsLight.plum;

  // ── Text ──────────────────────────────────────────────────────
  Color get textPrimary =>
      _isDark ? AppColorsPulse.textPrimary : AppColorsLight.textPrimary;
  Color get textSecondary =>
      _isDark ? AppColorsPulse.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted =>
      _isDark ? AppColorsPulse.textMuted : AppColorsLight.textMuted;

  // ── Semantic ──────────────────────────────────────────────────
  Color get success => _isDark ? AppColorsPulse.green : AppColorsLight.sage;
  Color get error => _isDark ? AppColorsPulse.red : AppColorsLight.rust;
  Color get warning => _isDark ? AppColorsPulse.yellow : AppColorsLight.yellow;

  // ── Glass / borders ───────────────────────────────────────────
  Color get glass =>
      _isDark ? AppColorsPulse.surface : AppColorsLight.glass;
  Color get glassBorder =>
      _isDark ? AppColorsPulse.border : AppColorsLight.glassBorder;
  Color get hairline =>
      _isDark ? AppColorsPulse.hairline : AppColorsLight.hairline;

  // ── Nav / Topbar ──────────────────────────────────────────────
  Color get topbarBg =>
      _isDark ? AppColorsPulse.topbarBg : AppColorsLight.topbarBg;
  Color get bottomNavBg =>
      _isDark ? AppColorsPulse.bottomNavBg : AppColorsLight.bottomNavBg;
}
