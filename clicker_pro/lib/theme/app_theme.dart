// lib/theme/app_theme.dart
//
// Clicker Pro — Theme entry point
// Two mobile themes: ClickerPro (light, default) and Noir (dark).
// Sunset Studio / Sunrise Pulse / Deep Ocean are retired (kept only as
// backward-compat shims below).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme_clicker.dart';
import 'app_theme_light.dart';
import 'app_theme_noir.dart';
import 'app_theme_web.dart';

/// ============================================================
/// SPACING — 8px base scale (v15 spec)
/// ============================================================
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// ============================================================
/// RADII — v15 Sunset Studio: 18–24px cards · Sunrise Pulse: 10–14px
/// ============================================================
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;
  static const double pill = 999;
}

/// ============================================================
/// TYPOGRAPHY — theme-aware shared accessor.
///   • ClickerPro (default): brand + body = Hanken Grotesk · mono = IBM Plex Mono
///   • Noir (dark)         : brand + body = Space Grotesk · mono = JetBrains Mono
///
/// Fonts resolve per the active palette so shared widgets and auth/onboarding
/// screens that read AppText.* pick up the right typeface automatically.
/// ============================================================
class AppText {
  AppText._();

  static final String? _hanken = GoogleFonts.hankenGrotesk().fontFamily;
  static final String? _spaceGrotesk = GoogleFonts.spaceGrotesk().fontFamily;
  static final String? _ibmMono = GoogleFonts.ibmPlexMono().fontFamily;
  static final String? _jetMono = GoogleFonts.jetBrainsMono().fontFamily;

  static bool get _noir => AppColors.active == ActivePalette.noirDark;

  // ClickerPro uses Hanken for both brand + body; Noir uses Space Grotesk for
  // both (its mono/grotesk pairing is the theme's signature).
  static String? get _brandFont => _noir ? _spaceGrotesk : _hanken;
  static String? get _bodyFont => _noir ? _spaceGrotesk : _hanken;
  // Mono: JetBrains Mono on Noir, IBM Plex Mono on ClickerPro.
  static String? get _monoFont => _noir ? _jetMono : _ibmMono;

  /// Public theme-aware font families — use these instead of hardcoded
  /// 'Montserrat'/'Poppins' strings (which were never bundled and fell back to
  /// the platform default). Resolve per the active palette.
  static String? get brandFontFamily => _brandFont;
  static String? get bodyFontFamily => _bodyFont;
  static String? get monoFontFamily => _monoFont;

  /// Fixed ClickerPro (Hanken) family — for the auth/onboarding brand chrome
  /// that must always read as the ClickerPro spec regardless of the saved
  /// theme (those screens show before/around the theme toggle).
  static String? get clickerBrandFontFamily => _hanken;

  static TextStyle get brand => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    // ClickerPro: Hanken 800, tight. Noir: Space Grotesk 700, tight.
    fontWeight: _noir ? FontWeight.w700 : FontWeight.w800,
    color: AppColors.film,
    height: 1.1,
    letterSpacing: -0.02 * 22,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: _noir ? FontWeight.w700 : FontWeight.w800,
    color: AppColors.teal,
    height: 1.1,
    letterSpacing: -0.02 * 22,
  );

  static TextStyle get metricValue => TextStyle(
    fontFamily: _brandFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.0,
    letterSpacing: -0.5,
  );

  static TextStyle get paymentAmount => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.1,
  );

  static TextStyle get weatherTemp => TextStyle(
    fontFamily: _brandFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.0,
  );

  static TextStyle get weekdayNumber => TextStyle(
    fontFamily: _brandFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.0,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.film,
    height: 1.5,
  );

  static TextStyle get bodyDim => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.filmDim,
    height: 1.5,
  );

  static TextStyle get quickActionLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.film,
    height: 1.2,
  );

  static TextStyle get announcementTitle => TextStyle(
    fontFamily: _brandFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.3,
  );

  static TextStyle get sectionTitle => TextStyle(
    fontFamily: _monoFont,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.teal,
    height: 1.2,
    letterSpacing: 1.95,
  );

  static TextStyle get metricLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.filmDim,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get weekdayLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.filmDim,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get brandSub => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.filmDim,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static TextStyle get pillChip => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.filmDim,
    height: 1.0,
    letterSpacing: 0.5,
  );

  static TextStyle get navLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.filmDim,
    height: 1.0,
    letterSpacing: 0.3,
  );
}

/// ============================================================
/// GLASS DECORATIONS (Sunset Studio)
/// ============================================================
class AppDecorations {
  AppDecorations._();

  static BoxDecoration glassCard({double radius = AppRadius.xl, Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColors.glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1C1917),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x14803500),
          blurRadius: 24,
          spreadRadius: -6,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration tintedGlassCard({
    required Color tint,
    double radius = AppRadius.xl,
  }) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1C1917),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x14803500),
          blurRadius: 24,
          spreadRadius: -6,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration iconWrap(Color tint, {double radius = AppRadius.md}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChip({Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColors.glass,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.glassBorder, width: 1),
    );
  }

  static BoxDecoration get topbar => BoxDecoration(
    color: AppColors.topbarBg,
    border: Border(
      bottom: BorderSide(color: AppColors.topbarBorder, width: 1),
    ),
  );

  static BoxDecoration get bottomNav => BoxDecoration(
    color: AppColors.bottomNavBg,
    border: Border(top: BorderSide(color: AppColors.bottomNavBorder, width: 1)),
  );
}

class AppFilters {
  AppFilters._();
  static ImageFilter blur20 = ImageFilter.blur(sigmaX: 20, sigmaY: 20);
  static ImageFilter blur40 = ImageFilter.blur(sigmaX: 40, sigmaY: 40);
}

class AppTheme {
  AppTheme._();

  /// ClickerPro — the DEFAULT mobile theme (Hanken Grotesk + #E2620E, per
  /// CLICKERPRO_DESIGN_SPEC.md). Delegates to AppThemeClicker.
  static ThemeData clickerPro() => AppThemeClicker.theme();

  /// Sunset Studio — the earlier warm editorial theme (Playfair + #FF6200).
  /// Kept as the secondary mobile theme. Delegates to AppThemeLight.
  static ThemeData sunsetStudio() => AppThemeLight.light();

  /// Noir — the DARK theme (near-black canvas, lime #C8F252, Space Grotesk +
  /// JetBrains Mono). Built to CLICKERPRO_DARK_FLUTTER_SPEC.md. Delegates to
  /// AppThemeNoir.
  static ThemeData noirDark() => AppThemeNoir.theme();

  /// Web base theme — neutral placeholder scaffold driven by WebTheme tokens.
  /// Used as MaterialApp.theme on the web build only (see app.dart). Awaiting
  /// the new Claude Design theme; swap WebTheme's values to reskin.
  static ThemeData web() => AppThemeWeb.theme();

  // ── Backward-compat shims ──────────────────────────────────────────
  // Older callers referenced these names. Sunrise Pulse / Deep Ocean are
  // retired, so they resolve to Sunset Studio; `dark()` now resolves to the
  // real Noir dark theme.
  static ThemeData sunrisePulse() => sunsetStudio();
  static ThemeData dark() => noirDark();
  static ThemeData orangeHorizon() => sunsetStudio();
  static ThemeData oceanDeep() => sunsetStudio();
}
