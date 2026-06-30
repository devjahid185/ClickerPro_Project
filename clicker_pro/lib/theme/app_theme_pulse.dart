// lib/theme/app_theme_pulse.dart
//
// Clicker Pro v15 — Sunrise Pulse dark ThemeData
// Bold · high-contrast · fast-feeling
// Outfit for both headlines and body (no serif)
// Tighter corners (10–14 px) · flat fills · 2 px high-contrast borders

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors_pulse.dart';

/// ============================================================
/// PULSE TYPOGRAPHY
/// Both headline and body: Outfit (geometric sans)
/// Mono labels: IBM Plex Mono
/// No Playfair Display / no serif
/// ============================================================
class AppTextPulse {
  AppTextPulse._();

  static final String? _bodyFont = GoogleFonts.outfit().fontFamily;
  static final String? _monoFont = GoogleFonts.ibmPlexMono().fontFamily;

  static TextStyle get brand => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColorsPulse.textPrimary,
    height: 1.1,
    letterSpacing: -0.3,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColorsPulse.primary,
    height: 1.1,
  );

  static TextStyle get metricValue => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColorsPulse.textPrimary,
    height: 1.0,
    letterSpacing: -1.0,
  );

  static TextStyle get paymentAmount => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textPrimary,
    height: 1.1,
  );

  static TextStyle get weatherTemp => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColorsPulse.textPrimary,
    height: 1.0,
  );

  static TextStyle get weekdayNumber => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textPrimary,
    height: 1.0,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsPulse.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyDim => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsPulse.textSecondary,
    height: 1.5,
  );

  static TextStyle get quickActionLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorsPulse.textPrimary,
    height: 1.2,
  );

  static TextStyle get announcementTitle => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textPrimary,
    height: 1.3,
  );

  static TextStyle get sectionTitle => TextStyle(
    fontFamily: _monoFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.primary,
    height: 1.2,
    letterSpacing: 2.0,
  );

  static TextStyle get metricLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textSecondary,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get weekdayLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textSecondary,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get brandSub => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColorsPulse.textSecondary,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static TextStyle get pillChip => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsPulse.textSecondary,
    height: 1.0,
    letterSpacing: 0.5,
  );

  static TextStyle get navLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColorsPulse.textSecondary,
    height: 1.0,
    letterSpacing: 0.3,
  );
}

/// ============================================================
/// PULSE DECORATIONS (flat fills, 2px borders, tight corners)
/// ============================================================
class AppDecorationsPulse {
  AppDecorationsPulse._();

  static BoxDecoration glassCard({double radius = 12, Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColorsPulse.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColorsPulse.border, width: 2),
    );
  }

  static BoxDecoration tintedGlassCard({
    required Color tint,
    double radius = 12,
  }) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColorsPulse.border, width: 2),
    );
  }

  static BoxDecoration iconWrap(Color tint, {double radius = 10}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChip({Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColorsPulse.surfaceAlt,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColorsPulse.border, width: 2),
    );
  }

  static BoxDecoration get topbar => const BoxDecoration(
    color: AppColorsPulse.topbarBg,
    border: Border(
      bottom: BorderSide(color: AppColorsPulse.topbarBorder, width: 1),
    ),
  );

  static BoxDecoration get bottomNav => const BoxDecoration(
    color: AppColorsPulse.bottomNavBg,
    border: Border(top: BorderSide(color: AppColorsPulse.bottomNavBorder, width: 1)),
  );
}

/// ============================================================
/// SUNRISE PULSE ThemeData
/// ============================================================
class AppThemePulse {
  AppThemePulse._();

  static ThemeData dark() {
    // NOTE: named `dark()` only because it fills MaterialApp's darkTheme slot;
    // Sunrise Pulse is a LIGHT theme in v15.
    final base = ThemeData.light();
    final outfitTextTheme = GoogleFonts.outfitTextTheme(base.textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsPulse.bg,
      canvasColor: AppColorsPulse.bg,
      primaryColor: AppColorsPulse.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColorsPulse.primary,
        secondary: AppColorsPulse.amber,
        tertiary: AppColorsPulse.indigo,
        surface: AppColorsPulse.surface,
        surfaceContainerHighest: AppColorsPulse.surfaceAlt,
        error: AppColorsPulse.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColorsPulse.textPrimary,
      ),
      textTheme: outfitTextTheme
          .apply(
            bodyColor: AppColorsPulse.textPrimary,
            displayColor: AppColorsPulse.textPrimary,
          )
          .copyWith(
            bodyMedium: outfitTextTheme.bodyMedium?.copyWith(
              color: AppColorsPulse.textPrimary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            bodySmall: outfitTextTheme.bodySmall?.copyWith(
              color: AppColorsPulse.textSecondary,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            titleMedium: outfitTextTheme.titleMedium?.copyWith(
              color: AppColorsPulse.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: outfitTextTheme.titleLarge?.copyWith(
              color: AppColorsPulse.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            labelLarge: outfitTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
      splashColor: AppColorsPulse.primarySoft,
      highlightColor: AppColorsPulse.primarySoft,
      dividerColor: AppColorsPulse.border,
      cardColor: AppColorsPulse.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsPulse.bg,
        foregroundColor: AppColorsPulse.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsPulse.surface,
        selectedItemColor: AppColorsPulse.primary,
        unselectedItemColor: AppColorsPulse.textSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsPulse.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColorsPulse.border, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsPulse.surface,
        modalBackgroundColor: AppColorsPulse.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsPulse.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColorsPulse.border, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsPulse.surfaceAlt,
        hintStyle: const TextStyle(color: AppColorsPulse.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColorsPulse.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColorsPulse.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColorsPulse.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColorsPulse.red, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsPulse.surfaceAlt,
        contentTextStyle: const TextStyle(
          color: AppColorsPulse.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColorsPulse.border, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsPulse.primary;
          }
          return AppColorsPulse.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsPulse.primarySoft;
          }
          return AppColorsPulse.surfaceAlt;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColorsPulse.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsPulse.primary;
            }
            return AppColorsPulse.surfaceAlt;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColorsPulse.border, width: 2),
          ),
        ),
      ),
    );
  }
}
