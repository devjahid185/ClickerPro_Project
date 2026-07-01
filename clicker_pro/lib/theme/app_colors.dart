// lib/theme/app_colors.dart
//
// Clicker Pro — AppColors (two-theme static accessor).
//
// This class is the single static colour accessor used across the mobile
// codebase (custom-painted widgets read it without a BuildContext). It
// delegates to one of two palettes based on the active theme:
//   • AppColorsClicker — the DEFAULT ClickerPro theme (#E2620E, per spec)
//   • AppColorsLight   — the legacy Sunset Studio theme (#FF6200)
//
// app.dart sets `AppColors.active` whenever the theme changes so every getter
// resolves to the right palette. `const` fields cannot switch at runtime, so
// those keep the ClickerPro (default) values for legacy const call sites;
// prefer the getters below in new code.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_colors_clicker.dart';
import 'app_colors_light.dart';

/// Which palette AppColors resolves to. Mirrors AppThemeMode (mobile).
enum ActivePalette { clickerPro, sunsetStudio }

class AppColors {
  AppColors._();

  // ============================================================
  // 🌗 THEME SWITCH — flipped by app.dart on every theme change.
  // ============================================================
  static ActivePalette active = ActivePalette.clickerPro;

  static bool get _sunset => active == ActivePalette.sunsetStudio;

  /// Backward-compat: some old code toggled `isDark`. It now selects Sunset.
  /// (Neither theme is actually dark — both are light.)
  static bool get isDark => _sunset;
  static set isDark(bool v) =>
      active = v ? ActivePalette.sunsetStudio : ActivePalette.clickerPro;

  // ============================================================
  // ☀️ SURFACES
  // ============================================================
  static Color get appBg =>
      _sunset ? AppColorsLight.cream : AppColorsClicker.background;

  // On web, cards are solid clean white on the neutral page canvas.
  static Color get surface {
    if (kIsWeb) return Colors.white;
    return _sunset ? AppColorsLight.glass : AppColorsClicker.surface;
  }

  static Color get surfaceAlt {
    if (kIsWeb) return const Color(0xFFF7F8FA);
    return _sunset ? AppColorsLight.creamDark : AppColorsClicker.surfaceAlt;
  }

  // Backward-compat aliases
  static Color get voidBlack => appBg;
  static Color get voidLight => surface;
  static Color get voidElevated => surfaceAlt;
  static Color get void3 => surfaceAlt;
  static Color get void2 => surface;

  // ============================================================
  // 🎨 PRIMARY ACCENT
  // ClickerPro = #E2620E · Sunset Studio = #FF6200
  // ============================================================

  // Static const ramp — ClickerPro brand orange (used in const contexts).
  static const Color primary50 = Color(0xFFFDF0E7);
  static const Color primary100 = Color(0xFFFAD9C2);
  static const Color primary200 = Color(0xFFF3B98C);
  static const Color primary300 = Color(0xFFEE9A56);
  static const Color primary400 = Color(0xFFF89A2B); // primary light
  static const Color primary500 = Color(0xFFE2620E); // ClickerPro brand orange
  static const Color primary600 = Color(0xFFC9560C);
  static const Color primary700 = Color(0xFFB84E0A); // primary dark
  static const Color primary800 = Color(0xFF8F3D08);
  static const Color primary900 = Color(0xFF662B06);

  // Theme-aware getters (use these in non-const contexts)
  static Color get orange =>
      _sunset ? AppColorsLight.terracotta : AppColorsClicker.primary;
  static Color get orangeLight =>
      _sunset ? AppColorsLight.terracottaLight : AppColorsClicker.primaryLight;
  static Color get orangeSoft =>
      _sunset ? AppColorsLight.terracottaSoft : AppColorsClicker.primarySoft;
  static Color get orangeGlow =>
      _sunset ? AppColorsLight.terracottaGlow : AppColorsClicker.primaryGlow;

  // Static const fallbacks — ClickerPro (default) values for const call sites.
  static const Color orangeConst = AppColorsClicker.primary;
  static const Color redConst = AppColorsClicker.danger;
  static const Color greenConst = AppColorsClicker.success;
  static const Color goldConst = AppColorsClicker.warning;
  static const Color indigoConst = AppColorsClicker.infoBlue;

  // Backward-compat aliases
  static Color get teal => orange;
  static Color get tealLight => orangeLight;
  static Color get tealSoft => orangeSoft;
  static Color get tealGlow => orangeGlow;
  static Color get accent => orange;
  static Color get accentLight => orangeLight;
  static Color get signalOrange => orange;

  // ============================================================
  // 🟡 GOLD / AMBER
  // ============================================================
  static Color get gold =>
      _sunset ? AppColorsLight.gold : AppColorsClicker.warning;
  static Color get goldSoft =>
      _sunset ? AppColorsLight.goldSoft : AppColorsClicker.goldSoft;

  // ============================================================
  // 💜 PURPLE / INFO
  // ============================================================
  static Color get purple =>
      _sunset ? AppColorsLight.plum : AppColorsClicker.accentViolet;
  static Color get purpleSoft =>
      _sunset ? AppColorsLight.plumSoft : AppColorsClicker.plumSoft;
  static Color get indigo =>
      _sunset ? const Color(0xFF2563EB) : AppColorsClicker.infoBlue;
  static const Color indigoSoft = Color(0x263541AF);
  static Color get info => indigo;
  static const Color infoSoft = indigoSoft;

  // ============================================================
  // 📝 TEXT
  // ============================================================
  static Color get film =>
      _sunset ? AppColorsLight.textPrimary : AppColorsClicker.textPrimary;
  static Color get filmDim =>
      _sunset ? AppColorsLight.textSecondary : AppColorsClicker.textSecondary;
  static Color get filmMuted =>
      _sunset ? AppColorsLight.textMuted : AppColorsClicker.textMuted;

  static Color get textPrimary => film;
  static Color get textSecondary => filmDim;
  static Color get textMuted => filmMuted;

  // Gray scale (neutral — theme-independent)
  static const Color gray50 = Color(0xFFFAFAF9);
  static const Color gray100 = Color(0xFFF5F5F4);
  static const Color gray200 = Color(0xFFE7E5E4);
  static const Color gray300 = Color(0xFFD6D3D1);
  static const Color gray400 = Color(0xFFA8A29E);
  static const Color gray500 = Color(0xFF78716C);
  static const Color gray600 = Color(0xFF57534E);
  static const Color gray700 = Color(0xFF44403C);
  static const Color gray800 = Color(0xFF292524);
  static const Color gray900 = Color(0xFF1C1917);

  // ============================================================
  // 🟢🔴 SEMANTIC / STATUS
  // ============================================================
  static Color get green =>
      _sunset ? AppColorsLight.sage : AppColorsClicker.success;
  static Color get greenSoft =>
      _sunset ? AppColorsLight.sageSoft : AppColorsClicker.greenSoft;
  static const Color success = AppColorsClicker.success;
  static const Color mint = AppColorsClicker.success;

  static Color get yellow =>
      _sunset ? AppColorsLight.yellow : AppColorsClicker.warning;
  static Color get yellowSoft =>
      _sunset ? AppColorsLight.yellowSoft : AppColorsClicker.yellowSoft;
  static const Color warning = AppColorsClicker.warning;

  static Color get red =>
      _sunset ? AppColorsLight.rust : AppColorsClicker.danger;
  static Color get redSoft =>
      _sunset ? AppColorsLight.rustSoft : AppColorsClicker.redSoft;
  static Color get error => red;
  static Color get danger => red;
  static Color get coral => red;

  // ============================================================
  // 🎨 DATA / STAT CARD COLOURS (ClickerPro dashboard — multi-colour)
  // Spec §1: intentional data cards, kept as-is on both themes.
  // ============================================================
  static const Color infoTeal = AppColorsClicker.infoTeal;
  static const Color infoBlue = AppColorsClicker.infoBlue;
  static const Color accentViolet = AppColorsClicker.accentViolet;

  // ============================================================
  // 🪟 CARD SURFACES
  // ============================================================
  static Color line([double alpha = 0.08]) =>
      Colors.black.withValues(alpha: alpha);

  static Color get glass {
    if (kIsWeb) return Colors.white;
    return _sunset ? AppColorsLight.glass : AppColorsClicker.surface;
  }
  static Color get glassBorder =>
      _sunset ? AppColorsLight.glassBorder : AppColorsClicker.glassBorder;
  static Color get glassHover =>
      _sunset ? AppColorsLight.glassHover : AppColorsClicker.glassHover;
  static Color get hairline =>
      _sunset ? AppColorsLight.hairline : AppColorsClicker.hairline;

  static Color get topbarBg =>
      _sunset ? AppColorsLight.topbarBg : AppColorsClicker.topbarBg;
  static Color get topbarBorder =>
      _sunset ? AppColorsLight.topbarBorder : AppColorsClicker.topbarBorder;
  static Color get bottomNavBg =>
      _sunset ? AppColorsLight.bottomNavBg : AppColorsClicker.bottomNavBg;
  static Color get bottomNavBorder =>
      _sunset ? AppColorsLight.bottomNavBorder : AppColorsClicker.bottomNavBorder;

  // ============================================================
  // 🌈 GRADIENTS
  // ============================================================
  static LinearGradient get orangeGradient => _sunset
      ? AppColorsLight.terracottaGradient
      : AppColorsClicker.orangeGradient;
  static const LinearGradient tealGradient = AppColorsClicker.orangeGradient;

  static LinearGradient get drawerHeaderGradient => _sunset
      ? AppColorsLight.drawerHeaderGradient
      : AppColorsClicker.drawerHeaderGradient;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDDB35A), AppColorsClicker.warning, Color(0xFF8A6A1E)],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0AE2620E), Color(0x00E2620E)],
  );

  // ============================================================
  // 🎨 CARD DECORATION HELPERS
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 18, Color? tint}) {
    if (_sunset) {
      return AppColorsLight.glassCardDecoration(radius: radius, tint: tint);
    }
    return AppColorsClicker.glassCardDecoration(radius: radius, tint: tint);
  }

  static BoxDecoration iconWrapDecoration(Color tint, {double radius = 12}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChipDecoration({Color? tint}) {
    if (_sunset) {
      return AppColorsLight.pillChipDecoration(tint: tint);
    }
    return AppColorsClicker.pillChipDecoration(tint: tint);
  }
}
