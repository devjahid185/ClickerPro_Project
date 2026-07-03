// lib/theme/app_colors.dart
//
// Clicker Pro — AppColors (two-theme static accessor: ClickerPro + Noir).
//
// This class is the single static colour accessor used across the mobile
// codebase (custom-painted widgets read it without a BuildContext). It
// delegates to one of two palettes based on the active theme:
//   • AppColorsClicker — the DEFAULT ClickerPro theme (LIGHT · #E2620E, per spec)
//   • AppColorsNoir    — the "Noir" DARK theme (near-black · lime #C8F252)
//
// app.dart sets `AppColors.active` whenever the theme changes so every getter
// resolves to the right palette. `const` fields cannot switch at runtime, so
// those keep the ClickerPro (default) values for legacy const call sites;
// prefer the getters below in new code.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_colors_clicker.dart';
import 'app_colors_noir.dart';

/// Which palette AppColors resolves to. Mirrors AppThemeMode (mobile).
enum ActivePalette { clickerPro, noirDark }

class AppColors {
  AppColors._();

  // ============================================================
  // 🌗 THEME SWITCH — flipped by app.dart on every theme change.
  // ============================================================
  static ActivePalette active = ActivePalette.clickerPro;

  static bool get _noir => active == ActivePalette.noirDark;

  /// Backward-compat: some old code toggled `isDark`. `true` now selects the
  /// Noir dark theme (the app's only genuinely dark theme); `false` restores
  /// the ClickerPro default.
  static bool get isDark => _noir;
  static set isDark(bool v) =>
      active = v ? ActivePalette.noirDark : ActivePalette.clickerPro;

  // ============================================================
  // ☀️ SURFACES
  // ============================================================
  static Color get appBg =>
      _noir ? AppColorsNoir.background : AppColorsClicker.background;

  // On web, cards are solid clean white on the neutral page canvas.
  static Color get surface {
    if (kIsWeb) return Colors.white;
    return _noir ? AppColorsNoir.surface : AppColorsClicker.surface;
  }

  static Color get surfaceAlt {
    if (kIsWeb) return const Color(0xFFF7F8FA);
    return _noir ? AppColorsNoir.surfaceAlt : AppColorsClicker.surfaceAlt;
  }

  // Backward-compat aliases
  static Color get voidBlack => appBg;
  static Color get voidLight => surface;
  static Color get voidElevated => surfaceAlt;
  static Color get void3 => surfaceAlt;
  static Color get void2 => surface;

  // ============================================================
  // 🎨 PRIMARY ACCENT
  // ClickerPro = #E2620E · Noir = lime #C8F252
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
      _noir ? AppColorsNoir.accent : AppColorsClicker.primary;
  static Color get orangeLight =>
      _noir ? AppColorsNoir.accent : AppColorsClicker.primaryLight;
  static Color get orangeSoft =>
      _noir ? AppColorsNoir.accentTint : AppColorsClicker.primarySoft;
  static Color get orangeGlow =>
      _noir ? AppColorsNoir.primaryGlow : AppColorsClicker.primaryGlow;

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

  /// The correct text/icon colour to place ON the primary accent fill.
  /// ClickerPro's orange takes white; Noir's lime takes near-black — using this
  /// instead of a hardcoded `Colors.white` keeps labels legible on both themes.
  static Color get onAccent =>
      _noir ? AppColorsNoir.onAccent : Colors.white;

  // ============================================================
  // 🟡 GOLD / AMBER
  // ============================================================
  static Color get gold =>
      _noir ? AppColorsNoir.day : AppColorsClicker.warning;
  static Color get goldSoft =>
      _noir ? AppColorsNoir.goldSoft : AppColorsClicker.goldSoft;

  // ============================================================
  // 💜 PURPLE / INFO
  // ============================================================
  static Color get purple =>
      _noir ? AppColorsNoir.night : AppColorsClicker.accentViolet;
  static Color get purpleSoft =>
      _noir ? AppColorsNoir.nightTint : AppColorsClicker.plumSoft;
  static Color get indigo =>
      _noir ? AppColorsNoir.night : AppColorsClicker.infoBlue;
  static const Color indigoSoft = Color(0x263541AF);
  static Color get info => indigo;
  static const Color infoSoft = indigoSoft;

  // ============================================================
  // 📝 TEXT
  // ============================================================
  static Color get film =>
      _noir ? AppColorsNoir.text : AppColorsClicker.textPrimary;
  static Color get filmDim =>
      _noir ? AppColorsNoir.muted : AppColorsClicker.textSecondary;
  static Color get filmMuted =>
      _noir ? AppColorsNoir.faint : AppColorsClicker.textMuted;

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
      _noir ? AppColorsNoir.paid : AppColorsClicker.success;
  static Color get greenSoft =>
      _noir ? AppColorsNoir.paidTint : AppColorsClicker.greenSoft;
  static const Color success = AppColorsClicker.success;
  static const Color mint = AppColorsClicker.success;

  static Color get yellow =>
      _noir ? AppColorsNoir.day : AppColorsClicker.warning;
  static Color get yellowSoft =>
      _noir ? AppColorsNoir.goldSoft : AppColorsClicker.yellowSoft;
  static const Color warning = AppColorsClicker.warning;

  static Color get red =>
      _noir ? AppColorsNoir.due : AppColorsClicker.danger;
  static Color get redSoft =>
      _noir ? AppColorsNoir.dueTint : AppColorsClicker.redSoft;
  static Color get error => red;
  static Color get danger => red;
  static Color get coral => red;

  // ============================================================
  // 🎨 DATA / STAT CARD COLOURS (dashboard — multi-colour)
  // ClickerPro keeps its intentional data palette; Noir maps them onto its own
  // shift/semantic set so the stat cards stay legible on the near-black canvas.
  // ============================================================
  static Color get infoTeal =>
      _noir ? AppColorsNoir.infoTeal : AppColorsClicker.infoTeal;
  static Color get infoBlue =>
      _noir ? AppColorsNoir.infoBlue : AppColorsClicker.infoBlue;
  static Color get accentViolet =>
      _noir ? AppColorsNoir.accentViolet : AppColorsClicker.accentViolet;
  static Color get sageData =>
      _noir ? AppColorsNoir.sageData : AppColorsClicker.sageData;

  // ============================================================
  // 🪟 CARD SURFACES
  // ============================================================
  // Hairline: black wash on the light themes, white wash on Noir dark so the
  // stroke stays visible against the near-black canvas.
  static Color line([double alpha = 0.08]) =>
      (_noir ? Colors.white : Colors.black).withValues(alpha: alpha);

  static Color get glass {
    if (kIsWeb) return Colors.white;
    return _noir ? AppColorsNoir.card : AppColorsClicker.surface;
  }
  static Color get glassBorder =>
      _noir ? AppColorsNoir.stroke : AppColorsClicker.glassBorder;
  static Color get glassHover =>
      _noir ? AppColorsNoir.glassHover : AppColorsClicker.glassHover;
  static Color get hairline =>
      _noir ? AppColorsNoir.strokeStrong : AppColorsClicker.hairline;

  static Color get topbarBg =>
      _noir ? AppColorsNoir.topbarBg : AppColorsClicker.topbarBg;
  static Color get topbarBorder =>
      _noir ? AppColorsNoir.topbarBorder : AppColorsClicker.topbarBorder;
  static Color get bottomNavBg =>
      _noir ? AppColorsNoir.bottomNavBg : AppColorsClicker.bottomNavBg;
  static Color get bottomNavBorder =>
      _noir ? AppColorsNoir.bottomNavBorder : AppColorsClicker.bottomNavBorder;

  // ============================================================
  // 🌈 GRADIENTS
  // ============================================================
  static LinearGradient get orangeGradient => _noir
      ? AppColorsNoir.orangeGradient
      : AppColorsClicker.orangeGradient;
  static const LinearGradient tealGradient = AppColorsClicker.orangeGradient;

  static LinearGradient get drawerHeaderGradient => _noir
      ? AppColorsNoir.drawerHeaderGradient
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
    if (_noir) {
      return AppColorsNoir.glassCardDecoration(radius: radius, tint: tint);
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
    if (_noir) {
      return AppColorsNoir.pillChipDecoration(tint: tint);
    }
    return AppColorsClicker.pillChipDecoration(tint: tint);
  }
}
