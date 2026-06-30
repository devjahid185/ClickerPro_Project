// lib/theme/app_colors.dart
//
// Clicker Pro v15 — AppColors (Sunset Studio + Sunrise Pulse compat layer)
//
// This class serves as the single static accessor used throughout the
// existing codebase. When `isDark` is true (Sunrise Pulse), all getters
// delegate to AppColorsPulse. When false (Sunset Studio), they delegate
// to AppColorsLight.
//
// New code should prefer ThemeAwareColors.of(context) or import the
// specific palette (AppColorsLight / AppColorsPulse) directly.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_colors_light.dart';
import 'app_colors_pulse.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // 🌗 THEME SWITCH — flipped by app.dart
  // ============================================================
  static bool isDark = false; // false = Sunset Studio, true = Sunrise Pulse

  // ============================================================
  // ☀️ SURFACES
  // ============================================================
  // On web the page background is the WebShell's ambient backdrop, so the
  // scaffold/app background is transparent (handled per-screen). appBg itself
  // is kept for any explicit fills.
  static Color get appBg => isDark ? AppColorsPulse.bg : AppColorsLight.cream;

  // Card / elevated surfaces. v16: web uses solid (no glass) — clean white
  // cards on the neutral page canvas. Mobile keeps its palette surface.
  static Color get surface {
    if (kIsWeb) return Colors.white;
    return isDark ? AppColorsPulse.surface : AppColorsLight.glass;
  }

  static Color get surfaceAlt {
    if (kIsWeb) return const Color(0xFFF7F8FA);
    return isDark ? AppColorsPulse.surfaceAlt : AppColorsLight.creamDark;
  }

  // Backward-compat aliases
  static Color get voidBlack => appBg;
  static Color get voidLight => surface;
  static Color get voidElevated => surfaceAlt;
  static Color get void3 => surfaceAlt;
  static Color get void2 => surface;

  // ============================================================
  // 🎨 PRIMARY ACCENT
  // Sunset Studio = terracotta · Sunrise Pulse = sunrise red-orange
  // ============================================================

  // Static constants (used in const contexts — Signal Orange ramp).
  // Heaven: primary must be orange everywhere — this swatch drives the
  // finance hero gradient and other const usages.
  static const Color primary50 = Color(0xFFFFF3E8);
  static const Color primary100 = Color(0xFFFFE0C2);
  static const Color primary200 = Color(0xFFFFC089);
  static const Color primary300 = Color(0xFFFF9F50);
  static const Color primary400 = Color(0xFFFF8534); // orange light
  static const Color primary500 = Color(0xFFFF6200); // Signal Orange (default)
  static const Color primary600 = Color(0xFFE85700);
  static const Color primary700 = Color(0xFFC44900);
  static const Color primary800 = Color(0xFF9C3A00);
  static const Color primary900 = Color(0xFF6B2800);

  // Theme-aware getters (use these in non-const contexts)
  static Color get orange =>
      isDark ? AppColorsPulse.primary : AppColorsLight.terracotta;
  static Color get orangeLight =>
      isDark ? AppColorsPulse.primaryLight : AppColorsLight.terracottaLight;
  static Color get orangeSoft =>
      isDark ? AppColorsPulse.primarySoft : AppColorsLight.terracottaSoft;
  static Color get orangeGlow =>
      isDark ? AppColorsPulse.primaryGlow : AppColorsLight.terracottaGlow;

  // Static const fallbacks — compile-time safe for const constructors.
  // These resolve to Sunset Studio values and are for legacy const usage only.
  // Prefer the theme-aware getters above in new code.
  static const Color orangeConst = AppColorsLight.terracotta;
  static const Color redConst = AppColorsLight.rust;
  static const Color greenConst = AppColorsLight.sage;
  static const Color goldConst = AppColorsLight.gold;
  static const Color indigoConst = Color(0xFF2563EB);

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
  static const Color gold = AppColorsLight.gold; // Sunset Studio gold
  static const Color goldSoft = AppColorsLight.goldSoft;

  // ============================================================
  // 💜 PURPLE / INFO
  // ============================================================
  static const Color purple = AppColorsLight.plum;
  static const Color purpleSoft = AppColorsLight.plumSoft;
  static const Color indigo = Color(0xFF2563EB);
  static const Color indigoSoft = Color(0x262563EB);
  static const Color info = indigo;
  static const Color infoSoft = indigoSoft;

  // ============================================================
  // 📝 TEXT
  // ============================================================
  static Color get film =>
      isDark ? AppColorsPulse.textPrimary : AppColorsLight.textPrimary;
  static Color get filmDim =>
      isDark ? AppColorsPulse.textSecondary : AppColorsLight.textSecondary;
  static Color get filmMuted =>
      isDark ? AppColorsPulse.textMuted : AppColorsLight.textMuted;

  static Color get textPrimary => film;
  static Color get textSecondary => filmDim;
  static Color get textMuted => filmMuted;

  // Gray scale (Sunset Studio — used in light mode only)
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
      isDark ? AppColorsPulse.green : AppColorsLight.sage;
  static Color get greenSoft =>
      isDark ? AppColorsPulse.greenSoft : AppColorsLight.sageSoft;
  static const Color success = AppColorsLight.sage;
  static const Color mint = AppColorsLight.sage;

  static Color get yellow =>
      isDark ? AppColorsPulse.yellow : AppColorsLight.yellow;
  static Color get yellowSoft =>
      isDark ? AppColorsPulse.yellowSoft : AppColorsLight.yellowSoft;
  static const Color warning = AppColorsLight.yellow;

  static Color get red =>
      isDark ? AppColorsPulse.red : AppColorsLight.rust;
  static Color get redSoft =>
      isDark ? AppColorsPulse.redSoft : AppColorsLight.rustSoft;
  static Color get error => red;
  static Color get danger => red;
  static Color get coral => red;

  // ============================================================
  // 🪟 CARD SURFACES
  // ============================================================
  static Color line([double alpha = 0.08]) => isDark
      ? Colors.white.withValues(alpha: (alpha * 1.5).clamp(0.0, 1.0))
      : Colors.black.withValues(alpha: alpha);

  // On web we make the card surface translucent so the WebShell's rich
  // ambient backdrop shows through — that's what turns flat white cards into
  // real frosted glass. On mobile the surface stays fully opaque (phone UI
  // unchanged). The BackdropFilter blur lives in the GlassCard / WebShell;
  // here we only relax the fill opacity.
  static Color get glass {
    if (kIsWeb) return Colors.white;
    return isDark ? AppColorsPulse.surface : AppColorsLight.glass;
  }
  static Color get glassBorder =>
      isDark ? AppColorsPulse.border : AppColorsLight.glassBorder;
  static Color get glassHover =>
      isDark ? AppColorsPulse.surfaceAlt : AppColorsLight.glassHover;
  static Color get hairline =>
      isDark ? AppColorsPulse.hairline : AppColorsLight.hairline;

  static Color get topbarBg =>
      isDark ? AppColorsPulse.topbarBg : AppColorsLight.topbarBg;
  static Color get topbarBorder =>
      isDark ? AppColorsPulse.topbarBorder : AppColorsLight.topbarBorder;
  static Color get bottomNavBg =>
      isDark ? AppColorsPulse.bottomNavBg : AppColorsLight.bottomNavBg;
  static Color get bottomNavBorder =>
      isDark ? AppColorsPulse.bottomNavBorder : AppColorsLight.bottomNavBorder;

  // ============================================================
  // 🌈 GRADIENTS
  // ============================================================
  static LinearGradient get orangeGradient =>
      isDark ? AppColorsPulse.primaryGradient : AppColorsLight.terracottaGradient;
  static const LinearGradient tealGradient = AppColorsLight.terracottaGradient;

  static LinearGradient get drawerHeaderGradient => isDark
      ? AppColorsPulse.drawerHeaderGradient
      : AppColorsLight.drawerHeaderGradient;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9B45C), AppColorsLight.gold, Color(0xFF96702D)],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0AFF6200), Color(0x00FF6200)],
  );

  // ============================================================
  // 🎨 CARD DECORATION HELPERS
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 18, Color? tint}) {
    if (isDark) {
      return AppColorsPulse.glassCardDecoration(radius: radius, tint: tint);
    }
    return AppColorsLight.glassCardDecoration(radius: radius, tint: tint);
  }

  static BoxDecoration iconWrapDecoration(Color tint, {double radius = 12}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChipDecoration({Color? tint}) {
    if (isDark) {
      return AppColorsPulse.pillChipDecoration(tint: tint);
    }
    return AppColorsLight.pillChipDecoration(tint: tint);
  }
}
