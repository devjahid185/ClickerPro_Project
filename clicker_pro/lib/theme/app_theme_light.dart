// lib/theme/app_theme_light.dart
//
// Clicker Pro — Sunset Studio Light Theme ThemeData
// Playfair Display + Outfit + IBM Plex Mono + Hind Siliguri
// Dark and Light are completely different looks — not just a color swap.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors_light.dart';

/// ============================================================
/// LIGHT THEME TYPOGRAPHY
/// brand/display: Playfair Display (serif elegance)
/// sans/body: Outfit (clean geometric)
/// mono/labels: IBM Plex Mono (technical)
/// Bengali: Hind Siliguri
/// ============================================================
class AppTextLight {
  AppTextLight._();

  static final String? _brandFont = GoogleFonts.playfairDisplay().fontFamily;
  static final String? _bodyFont = GoogleFonts.outfit().fontFamily;
  static final String? _monoFont = GoogleFonts.ibmPlexMono().fontFamily;

  static TextStyle get brand => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.1,
    letterSpacing: 0.3,
  );

  static TextStyle get brandAccent => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColorsLight.terracotta,
    height: 1.1,
  );

  static TextStyle get metricValue => TextStyle(
    fontFamily: _brandFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.0,
    letterSpacing: -0.5,
  );

  static TextStyle get paymentAmount => TextStyle(
    fontFamily: _brandFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.1,
  );

  static TextStyle get weatherTemp => TextStyle(
    fontFamily: _brandFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.0,
  );

  static TextStyle get weekdayNumber => TextStyle(
    fontFamily: _brandFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.0,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsLight.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyDim => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsLight.textSecondary,
    height: 1.5,
  );

  static TextStyle get quickActionLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textPrimary,
    height: 1.2,
  );

  static TextStyle get announcementTitle => TextStyle(
    fontFamily: _brandFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    height: 1.3,
  );

  static TextStyle get sectionTitle => TextStyle(
    fontFamily: _monoFont,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.terracotta,
    height: 1.2,
    letterSpacing: 1.95,
  );

  static TextStyle get metricLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textSecondary,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get weekdayLabel => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textSecondary,
    height: 1.2,
    letterSpacing: 1.0,
  );

  static TextStyle get brandSub => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textSecondary,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static TextStyle get pillChip => TextStyle(
    fontFamily: _monoFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textSecondary,
    height: 1.0,
    letterSpacing: 0.5,
  );

  static TextStyle get navLabel => TextStyle(
    fontFamily: _bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textSecondary,
    height: 1.0,
    letterSpacing: 0.3,
  );
}

/// ============================================================
/// LIGHT THEME DECORATIONS
/// ============================================================
class AppDecorationsLight {
  AppDecorationsLight._();

  static BoxDecoration glassCard({double radius = 14, Color? tint}) {
    return BoxDecoration(
      color: tint ?? AppColorsLight.glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColorsLight.glassBorder, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration tintedGlassCard({
    required Color tint,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColorsLight.glassBorder, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
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
      color: tint ?? const Color(0xFFF4EBDD),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColorsLight.glassBorder, width: 1.5),
    );
  }

  static BoxDecoration topbar = const BoxDecoration(
    color: AppColorsLight.topbarBg,
    border: Border(
      bottom: BorderSide(color: AppColorsLight.topbarBorder, width: 1.5),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
  );

  static BoxDecoration bottomNav = const BoxDecoration(
    color: AppColorsLight.bottomNavBg,
    border: Border(
      top: BorderSide(color: AppColorsLight.bottomNavBorder, width: 1.5),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, -2)),
    ],
  );
}

class AppFiltersLight {
  AppFiltersLight._();
  static ImageFilter blur20 = ImageFilter.blur(sigmaX: 20, sigmaY: 20);
  static ImageFilter blur40 = ImageFilter.blur(sigmaX: 40, sigmaY: 40);
}

/// ============================================================
/// LIGHT ThemeData
/// ============================================================
class AppThemeLight {
  AppThemeLight._();

  static ThemeData light() {
    final base = ThemeData.light();
    final outfitTextTheme = GoogleFonts.outfitTextTheme(base.textTheme);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.cream,
      primaryColor: AppColorsLight.terracotta,
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.terracotta,
        secondary: AppColorsLight.plum,
        tertiary: AppColorsLight.brass,
        surface: AppColorsLight.creamDark,
        error: AppColorsLight.rust,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsLight.textPrimary,
      ),
      textTheme: outfitTextTheme.copyWith(
        bodyMedium: outfitTextTheme.bodyMedium?.copyWith(
          color: AppColorsLight.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: outfitTextTheme.bodySmall?.copyWith(
          color: AppColorsLight.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        titleMedium: outfitTextTheme.titleMedium?.copyWith(
          color: AppColorsLight.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      splashColor: AppColorsLight.terracottaSoft,
      highlightColor: AppColorsLight.terracottaSoft,
      dividerColor: AppColorsLight.hairline,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.cream,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Light background → DARK status-bar icons (time/network/battery),
        // otherwise the default light icons vanish against the cream bar.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsLight.glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColorsLight.glassBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColorsLight.glassBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.creamDeep,
        contentTextStyle: const TextStyle(
          color: AppColorsLight.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsLight.terracotta;
          }
          return AppColorsLight.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsLight.terracottaSoft;
          }
          return AppColorsLight.hairline;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsLight.cream;
            }
            return AppColorsLight.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsLight.terracotta;
            }
            return AppColorsLight.cream;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColorsLight.glassBorder),
          ),
        ),
      ),
    );
  }
}
