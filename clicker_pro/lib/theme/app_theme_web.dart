// lib/theme/app_theme_web.dart
//
// Clicker Pro — WEB-ONLY base ThemeData.
//
// This is the MaterialApp.theme used on the web build (mobile keeps
// AppTheme.sunsetStudio()). It styles the Material widgets (TextField,
// buttons, dialogs, snackbars…) so they match the web design language driven
// by WebTheme tokens — NOT the mobile cream/terracotta look.
//
// STATUS: CLICKERPRO DESIGN — reads from WebTheme, so it inherited the Signal
// Orange / warm off-white palette automatically when those token values were
// swapped. Body font is Hanken Grotesk to match the design source
// (ClickerPro Web.dc.html).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'web_theme.dart';

class AppThemeWeb {
  AppThemeWeb._();

  static ThemeData theme() {
    final base = ThemeData.light();
    // Hanken Grotesk is the design source's UI typeface (ClickerPro Web.dc.html).
    final textTheme = GoogleFonts.hankenGroteskTextTheme(base.textTheme);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: WebTheme.pageBg,
      primaryColor: WebTheme.orange,
      colorScheme: const ColorScheme.light(
        primary: WebTheme.orange,
        secondary: WebTheme.sage,
        tertiary: WebTheme.amber,
        surface: WebTheme.surface,
        error: WebTheme.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: WebTheme.ink,
      ),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: WebTheme.ink,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: WebTheme.inkSoft,
          fontSize: 13,
          height: 1.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: WebTheme.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      splashColor: WebTheme.orangeSoft,
      highlightColor: WebTheme.orangeSoft,
      dividerColor: WebTheme.hairline,
      appBarTheme: const AppBarTheme(
        backgroundColor: WebTheme.surface,
        foregroundColor: WebTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: WebTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          side: const BorderSide(color: WebTheme.hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: WebTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WebTheme.rPanel),
          side: const BorderSide(color: WebTheme.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WebTheme.sageTintSoft,
        hintStyle: const TextStyle(color: WebTheme.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WebTheme.sp4,
          vertical: WebTheme.sp3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          borderSide: const BorderSide(color: WebTheme.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          borderSide: const BorderSide(color: WebTheme.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          borderSide: const BorderSide(color: WebTheme.orange, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WebTheme.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.sp5,
            vertical: WebTheme.sp3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WebTheme.rButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: WebTheme.orange),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WebTheme.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WebTheme.rChip),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return WebTheme.orange;
          return WebTheme.inkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return WebTheme.orangeSoft;
          return WebTheme.hairline;
        }),
      ),
    );
  }
}
