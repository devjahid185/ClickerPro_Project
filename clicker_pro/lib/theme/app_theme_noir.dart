// lib/theme/app_theme_noir.dart
//
// Graphy7 — "Noir" DARK theme ThemeData + typography.
//
// Built EXACTLY to CLICKERPRO_DARK_FLUTTER_SPEC.md:
//   • Body / UI  : Space Grotesk (400/500/600/700) — headings, numbers, content
//   • Mono/labels: JetBrains Mono — ALL-CAPS micro-labels, tags, dates, headers
//   • Accent     : #C8F252 lime (the only "glow" colour)
//   • Canvas     : #060708 · Surface #0C0E11 · Card #14171C · Inset #1B1F26
//   • Radius     : chip 9, input 13, card 16, cardLg 22, nav 24
//
// The mono/grotesk pairing IS the theme's signature — do NOT substitute
// Inter/Roboto/Hanken. English-only.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_noir.dart';

/// Typography for the Noir dark theme.
///
/// Mirrors the AppTextClicker API so the shared theme-aware AppText accessor can
/// resolve to it. Sizes/weights/tracking follow the §1 typography table.
class AppTextNoir {
  AppTextNoir._();

  static final String? _bodyFont = GoogleFonts.spaceGrotesk().fontFamily;
  static final String? _monoFont = GoogleFonts.jetBrainsMono().fontFamily;

  static String? get bodyFontFamily => _bodyFont;
  static String? get monoFontFamily => _monoFont;

  // Brand wordmark: "Clicker" text + "Pro" accent, Grotesk 700, tight tracking.
  static TextStyle get brand => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.0,
    letterSpacing: -0.02 * 22,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.accent,
    height: 1.0,
    letterSpacing: -0.02 * 22,
  );

  // Big hero figure (dashboard "2", finance net) — Grotesk 700, very tight.
  static TextStyle get metricValue => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.0,
    letterSpacing: -0.03 * 36,
  );

  static TextStyle get paymentAmount => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.1,
    letterSpacing: -0.02 * 22,
  );

  static TextStyle get weatherTemp => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.0,
    letterSpacing: -0.02 * 32,
  );

  static TextStyle get weekdayNumber => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.0,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.text,
    height: 1.5,
  );

  static TextStyle get bodyDim => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.muted,
    height: 1.5,
  );

  static TextStyle get quickActionLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColorsNoir.muted,
    height: 1.2,
  );

  static TextStyle get announcementTitle => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.text,
    height: 1.3,
  );

  // Mono micro-labels — ALL CAPS, wide tracking. §1 typography table.
  // Accent eyebrow: Mono 10 / 500, 0.22em, UPPERCASE, accent.
  static TextStyle get sectionTitle => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.accent,
    height: 1.2,
    letterSpacing: 0.22 * 10,
  );

  // Section label: Mono 10 / 600, 0.12em, UPPERCASE, faint.
  static TextStyle get metricLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColorsNoir.faint,
    height: 1.2,
    letterSpacing: 0.12 * 10,
  );

  // Data tag / date: Mono 9 / 500, 0.06em, faint.
  static TextStyle get weekdayLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.faint,
    height: 1.2,
    letterSpacing: 0.06 * 9,
  );

  static TextStyle get brandSub => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.faint,
    letterSpacing: 0.22 * 10,
    height: 1.2,
  );

  static TextStyle get pillChip => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsNoir.faint,
    height: 1.0,
    letterSpacing: 0.1 * 10,
  );

  // Nav label: Mono 8.5 / 600–700, faint (accent when active).
  static TextStyle get navLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 8.5,
    fontWeight: FontWeight.w700,
    color: AppColorsNoir.faint,
    height: 1.0,
    letterSpacing: 0.04 * 8.5,
  );
}

/// ThemeData for the Noir dark theme. Spec §2.
class AppThemeNoir {
  AppThemeNoir._();

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColorsNoir.text, displayColor: AppColorsNoir.text);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsNoir.bg,
      primaryColor: AppColorsNoir.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsNoir.accent,
        onPrimary: AppColorsNoir.onAccent,
        secondary: AppColorsNoir.accent,
        onSecondary: AppColorsNoir.onAccent,
        tertiary: AppColorsNoir.night,
        surface: AppColorsNoir.surface,
        error: AppColorsNoir.due,
        onSurface: AppColorsNoir.text,
      ),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColorsNoir.text,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColorsNoir.muted,
          fontSize: 13,
          height: 1.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColorsNoir.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      splashColor: AppColorsNoir.accentTint,
      highlightColor: AppColorsNoir.accentTint,
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColorsNoir.stroke,
      cardColor: AppColorsNoir.card,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsNoir.bg,
        foregroundColor: AppColorsNoir.text,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Dark canvas → light status-bar icons.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsNoir.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsNoir.stroke),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsNoir.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsNoir.stroke),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsNoir.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsNoir.card,
        hintStyle: const TextStyle(color: AppColorsNoir.faint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColorsNoir.strokeStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColorsNoir.strokeStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColorsNoir.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsNoir.accent,
          foregroundColor: AppColorsNoir.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColorsNoir.accent),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsNoir.accent,
        foregroundColor: AppColorsNoir.onAccent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsNoir.surface,
        contentTextStyle: const TextStyle(
          color: AppColorsNoir.text,
          fontSize: 13,
        ),
        actionTextColor: AppColorsNoir.accent,
        closeIconColor: AppColorsNoir.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsNoir.accent;
          }
          return AppColorsNoir.faint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsNoir.accentTint;
          }
          return AppColorsNoir.inset;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColorsNoir.strokeStrong),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsNoir.onAccent;
            }
            return AppColorsNoir.muted;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsNoir.accent;
            }
            return AppColorsNoir.card;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColorsNoir.strokeStrong),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColorsNoir.text),
    );
  }
}
