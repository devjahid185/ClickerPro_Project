// lib/theme/theme_aware_colors.dart
//
// Graphy7 v15 — Theme-aware color accessor
// v15 ships a single theme (Sunset Studio), so every accessor resolves to
// AppColorsLight. The type is retained so existing call sites keep working
// and a future second theme can branch here again.

import 'package:flutter/material.dart';
import 'app_colors_light.dart';

class ThemeAwareColors {
  const ThemeAwareColors._();

  factory ThemeAwareColors.of(BuildContext context) {
    return const ThemeAwareColors._();
  }

  bool get isDark => false;

  // ── Surface ──────────────────────────────────────────────────
  Color get bg => AppColorsLight.cream;
  Color get surface => AppColorsLight.glass;
  Color get surfaceAlt => AppColorsLight.creamDark;
  Color get surfaceHigh => AppColorsLight.creamDeep;

  // Backward-compat
  Color get cream => bg;
  Color get creamDark => surfaceAlt;
  Color get voidElevated => surfaceAlt;

  // ── Primary accent ────────────────────────────────────────────
  Color get accent => AppColorsLight.terracotta;
  Color get accentLight => AppColorsLight.terracottaLight;
  Color get accentSoft => AppColorsLight.terracottaSoft;
  Color get accentGlow => AppColorsLight.terracottaGlow;

  // ── Secondary ─────────────────────────────────────────────────
  Color get gold => AppColorsLight.gold;
  Color get purple => AppColorsLight.plum;

  // ── Text ──────────────────────────────────────────────────────
  Color get textPrimary => AppColorsLight.textPrimary;
  Color get textSecondary => AppColorsLight.textSecondary;
  Color get textMuted => AppColorsLight.textMuted;

  // ── Semantic ──────────────────────────────────────────────────
  Color get success => AppColorsLight.sage;
  Color get error => AppColorsLight.rust;
  Color get warning => AppColorsLight.yellow;

  // ── Glass / borders ───────────────────────────────────────────
  Color get glass => AppColorsLight.glass;
  Color get glassBorder => AppColorsLight.glassBorder;
  Color get hairline => AppColorsLight.hairline;

  // ── Nav / Topbar ──────────────────────────────────────────────
  Color get topbarBg => AppColorsLight.topbarBg;
  Color get bottomNavBg => AppColorsLight.bottomNavBg;
}
