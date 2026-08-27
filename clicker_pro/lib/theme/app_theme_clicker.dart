// lib/theme/app_theme_clicker.dart
//
// Graphy7 — "Graphy7" theme ThemeData (the current DEFAULT).
//
// Built EXACTLY to CLICKERPRO_DESIGN_SPEC.md:
//   • Body / UI  : Hanken Grotesk (400/500/600/700/800)
//   • Mono/labels: IBM Plex Mono (ALL-CAPS micro-labels, wide tracking)
//   • Primary    : #E2620E (the only interactive colour)
//   • Canvas     : #FBFAF7 · Surface #FFFFFF · muted panel #F4F3EF
//   • Radius     : cards 18, hero 22, input 14, chip 13, icon tile 12
//
// English-only (no Bengali font). Do not substitute tokens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_clicker.dart';

/// Typography for the Graphy7 theme.
class AppTextClicker {
  AppTextClicker._();

  static final String? _bodyFont = GoogleFonts.hankenGrotesk().fontFamily;
  static final String? _monoFont = GoogleFonts.ibmPlexMono().fontFamily;

  // Brand wordmark: "Clicker" ink + "Pro" orange, Hanken 800, tight tracking.
  static TextStyle get brand => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColorsClicker.textPrimary,
    height: 1.0,
    letterSpacing: -0.04 * 22,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColorsClicker.primary,
    height: 1.0,
    letterSpacing: -0.04 * 22,
  );

  // Big hero figure (dashboard "2", finance net, etc.) — 800, very tight.
  static TextStyle get metricValue => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColorsClicker.textPrimary,
    height: 1.0,
    letterSpacing: -0.03 * 36,
  );

  static TextStyle get paymentAmount => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColorsClicker.textPrimary,
    height: 1.1,
    letterSpacing: -0.02 * 22,
  );

  static TextStyle get weatherTemp => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColorsClicker.textPrimary,
    height: 1.0,
    letterSpacing: -0.02 * 32,
  );

  static TextStyle get weekdayNumber => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColorsClicker.textPrimary,
    height: 1.0,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyDim => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textSecondary,
    height: 1.5,
  );

  static TextStyle get quickActionLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColorsClicker.textSecondary,
    height: 1.2,
  );

  static TextStyle get announcementTitle => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColorsClicker.textPrimary,
    height: 1.3,
  );

  // Mono micro-labels — ALL CAPS, wide tracking, paired with the orange rule.
  static TextStyle get sectionTitle => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.primary,
    height: 1.2,
    letterSpacing: 0.22 * 10,
  );

  static TextStyle get metricLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textMuted,
    height: 1.2,
    letterSpacing: 0.12 * 10,
  );

  static TextStyle get weekdayLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textMuted,
    height: 1.2,
    letterSpacing: 0.06 * 9,
  );

  static TextStyle get brandSub => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textMuted,
    letterSpacing: 0.34 * 10,
    height: 1.2,
  );

  static TextStyle get pillChip => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsClicker.textMuted,
    height: 1.0,
    letterSpacing: 0.1 * 10,
  );

  static TextStyle get navLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 8.5,
    fontWeight: FontWeight.w700,
    color: AppColorsClicker.textMuted,
    height: 1.0,
    letterSpacing: 0.04 * 8.5,
  );
}

/// ThemeData for the Graphy7 theme.
class AppThemeClicker {
  AppThemeClicker._();

  static ThemeData theme() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.hankenGroteskTextTheme(base.textTheme);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsClicker.background,
      primaryColor: AppColorsClicker.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColorsClicker.primary,
        secondary: AppColorsClicker.accentViolet,
        tertiary: AppColorsClicker.warning,
        surface: AppColorsClicker.surface,
        error: AppColorsClicker.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsClicker.textPrimary,
      ),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColorsClicker.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColorsClicker.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColorsClicker.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      splashColor: AppColorsClicker.primarySoft,
      highlightColor: AppColorsClicker.primarySoft,
      dividerColor: AppColorsClicker.hairline,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsClicker.background,
        foregroundColor: AppColorsClicker.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Light canvas → dark status-bar icons.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsClicker.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColorsClicker.glassBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsClicker.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColorsClicker.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsClicker.surface,
        hintStyle: const TextStyle(color: AppColorsClicker.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsClicker.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsClicker.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsClicker.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsClicker.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColorsClicker.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsClicker.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        actionTextColor: AppColorsClicker.primary,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsClicker.primary;
          }
          return AppColorsClicker.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsClicker.primarySoft;
          }
          return AppColorsClicker.hairline;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColorsClicker.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsClicker.primary;
            }
            return AppColorsClicker.surface;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColorsClicker.glassBorder),
          ),
        ),
      ),
    );
  }
}
