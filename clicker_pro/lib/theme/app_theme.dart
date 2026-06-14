// lib/theme/app_theme.dart
//
// Clicker Pro — Deep Ocean Dark Luxury Lens
// Single source of truth for typography, spacing, and decorations.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ============================================================
/// SPACING — 4px base scale
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
/// RADII
/// ============================================================
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double pill = 999;
}

/// ============================================================
/// TYPOGRAPHY — Orange Horizon Pro
///   - brand/display & headings: Poppins
///   - sans/body: Inter
///   - numbers/labels: Montserrat
/// Bengali fallback: Noto Sans Bengali (auto via Google Fonts)
/// ============================================================
class AppText {
  AppText._();

  static final String? _brandFont = GoogleFonts.poppins().fontFamily;
  static final String? _bodyFont = GoogleFonts.inter().fontFamily;
  static final String? _monoFont = GoogleFonts.montserrat().fontFamily;

  // --- Serif / Brand (Display, numbers) ---
  static TextStyle get brand => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.film,
    height: 1.1,
    letterSpacing: 0.5,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.teal,
    height: 1.1,
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

  // --- Sans (body) ---
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

  // --- Mono (uppercase labels, KEY:VALUE) ---
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
/// GLASS DECORATIONS
/// ============================================================
class AppDecorations {
  AppDecorations._();

  static BoxDecoration glassCard({double radius = AppRadius.lg, Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColors.glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1C1917), // 4% warm ink — crisp key
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x14803500), // 8% warm umber — soft ambient
          blurRadius: 24,
          spreadRadius: -6,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration tintedGlassCard({
    required Color tint,
    double radius = AppRadius.lg,
  }) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1C1917), // 4% warm ink — crisp key
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x14803500), // 8% warm umber — soft ambient
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

  // ── Deep Ocean dark palette ──────────────────────────────────────
  // Navy-to-abyss surfaces with the brand orange kept as the accent so
  // the two themes feel like the same product after dark.
  static const Color oceanBg = Color(0xFF0A1222); // abyss background
  static const Color oceanSurface = Color(0xFF111B2E); // card / sheet
  static const Color oceanSurfaceAlt = Color(0xFF18253C); // elevated
  static const Color oceanInk = Color(0xFFEAF1FB); // primary text
  static const Color oceanInkDim = Color(0xFF9DB0CC); // secondary text
  static const Color oceanBorder = Color(0x1FFFFFFF); // hairline (white 12%)

  /// Orange Horizon Pro theme. Named `dark()` only for backward
  /// compatibility with `app.dart` wiring — it now returns the light
  /// SaaS ThemeData.
  static ThemeData dark() => orangeHorizon();

  /// Deep Ocean dark theme (MOD-64). Darkens every Material surface —
  /// scaffold, app bars, bottom sheets, dialogs, inputs, nav, dividers —
  /// while keeping the orange brand accent.
  static ThemeData oceanDeep() {
    final base = ThemeData.dark();
    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oceanBg,
      canvasColor: oceanBg,
      primaryColor: AppColors.primary500,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary500,
        secondary: AppColors.gold,
        tertiary: AppColors.info,
        surface: oceanSurface,
        surfaceContainerHighest: oceanSurfaceAlt,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: oceanInk,
      ),
      textTheme: interTextTheme
          .apply(bodyColor: oceanInk, displayColor: oceanInk)
          .copyWith(
            bodyMedium: interTextTheme.bodyMedium?.copyWith(
              color: oceanInk,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            bodySmall: interTextTheme.bodySmall?.copyWith(
              color: oceanInkDim,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            titleMedium: interTextTheme.titleMedium?.copyWith(
              color: oceanInk,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: interTextTheme.titleLarge?.copyWith(
              color: oceanInk,
              fontWeight: FontWeight.w700,
            ),
          ),
      splashColor: AppColors.orangeSoft,
      highlightColor: AppColors.orangeSoft,
      dividerColor: oceanBorder,
      cardColor: oceanSurface,
      dialogTheme: const DialogThemeData(backgroundColor: oceanSurface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: oceanSurface,
        modalBackgroundColor: oceanSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: oceanBg,
        foregroundColor: oceanInk,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Dark background → LIGHT status-bar icons.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: oceanSurface,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: oceanInkDim,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oceanSurfaceAlt,
        hintStyle: const TextStyle(color: oceanInkDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oceanBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oceanBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary500),
        ),
      ),
    );
  }

  static ThemeData orangeHorizon() {
    final base = ThemeData.light();
    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.appBg,
      primaryColor: AppColors.primary500,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary500,
        secondary: AppColors.gold,
        tertiary: AppColors.info,
        surface: AppColors.surface,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.film,
      ),
      // Slightly heavier global weights for crisper, more legible text.
      textTheme: interTextTheme.copyWith(
        bodyLarge: interTextTheme.bodyLarge?.copyWith(
          color: AppColors.film,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(
          color: AppColors.film,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: interTextTheme.bodySmall?.copyWith(
          color: AppColors.filmDim,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: interTextTheme.titleMedium?.copyWith(
          color: AppColors.film,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: interTextTheme.titleLarge?.copyWith(
          color: AppColors.film,
          fontWeight: FontWeight.w700,
        ),
        labelLarge: interTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      splashColor: AppColors.orangeSoft,
      highlightColor: AppColors.orangeSoft,
      dividerColor: AppColors.hairline,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.film,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Match the status-bar icons to the active surface so time/network/
        // battery stay legible: dark icons on a light surface, light on dark.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: AppColors.isDark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: AppColors.isDark
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
    );
  }
}
