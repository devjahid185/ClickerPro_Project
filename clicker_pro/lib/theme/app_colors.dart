// lib/theme/app_colors.dart
//
// Clicker Pro — Orange Horizon Pro (Light SaaS theme)
// Bright orange identity on clean light surfaces.
//
// ⚠️ এই ফাইল backward compatible — পুরোনো কোডের
// AppColors.accent, AppColors.teal, AppColors.voidBlack, AppColors.film,
// AppColors.orange, AppColors.error — সব নামই কাজ করবে, শুধু এখন
// Orange Horizon Pro মান ফেরত দেবে।

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // ☀️ SURFACES (Light SaaS backgrounds)
  //   App #F8FAFC · Surface #FFFFFF · Secondary #F1F5F9
  // ============================================================
  static const Color appBg = Color(0xFFF8FAFC); // App background
  static const Color surface = Color(0xFFFFFFFF); // Card / surface
  static const Color surfaceAlt = Color(0xFFF1F5F9); // Secondary surface

  // 🔁 Backward-compat: old dark "void" names now map to light surfaces.
  static const Color voidBlack = appBg; // Main BG
  static const Color voidLight = surface; // Elevated surface
  static const Color voidElevated = surfaceAlt; // More elevated surface
  static const Color void3 = surfaceAlt;
  static const Color void2 = surface;

  // ============================================================
  // 🔶 PRIMARY ORANGE (Orange Horizon Pro)
  // ============================================================
  static const Color primary50 = Color(0xFFFFF4EB);
  static const Color primary100 = Color(0xFFFFE4CC);
  static const Color primary200 = Color(0xFFFFD0A3);
  static const Color primary300 = Color(0xFFFFBA75);
  static const Color primary400 = Color(0xFFFFA14A);
  static const Color primary500 = Color(0xFFFF6B00); // Brand orange
  static const Color primary600 = Color(0xFFE55F00);
  static const Color primary700 = Color(0xFFCC5500);
  static const Color primary800 = Color(0xFFA34400);
  static const Color primary900 = Color(0xFF803500);

  // Canonical accent + soft/glow tints used across the app.
  static const Color orange = primary500;
  static const Color orangeLight = primary400;
  static const Color orangeSoft = Color(0x1FFF6B00); // 12% primary
  static const Color orangeGlow = Color(0x33FF6B00); // 20% primary

  // 🔁 Backward-compat: teal/accent/signalOrange all map to brand orange.
  static const Color teal = primary500;
  static const Color tealLight = primary400;
  static const Color tealSoft = orangeSoft;
  static const Color tealGlow = orangeGlow;
  static const Color accent = primary500;
  static const Color accentLight = primary400;
  static const Color signalOrange = primary500;

  // ============================================================
  // 🟡 GOLD / SECONDARY WARM ACCENT
  // ============================================================
  static const Color gold = Color(0xFFF59E0B); // warm amber
  static const Color goldSoft = Color(0x26F59E0B);

  // ============================================================
  // 💜 PURPLE / INFO TERTIARY
  // ============================================================
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0x267C3AED);
  static const Color indigo = Color(0xFF2563EB); // Info blue
  static const Color indigoSoft = Color(0x262563EB);

  // ============================================================
  // 📝 TEXT (Gray scale on light)
  // ============================================================
  static const Color film = Color(0xFF111827); // Gray 900 — primary text
  static const Color filmDim = Color(0xFF6B7280); // Gray 500 — secondary
  static const Color filmMuted = Color(0xFF9CA3AF); // Gray 400 — tertiary

  static const Color textPrimary = film;
  static const Color textSecondary = filmDim;
  static const Color textMuted = filmMuted;

  // Gray ramp (for borders, dividers, fills)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ============================================================
  // 🟢🔴 SEMANTIC / STATUS COLORS
  // ============================================================
  static const Color green = Color(0xFF16A34A); // Success
  static const Color greenSoft = Color(0x2616A34A);
  static const Color success = green;
  static const Color mint = green;

  static const Color yellow = Color(0xFFF59E0B); // Warning
  static const Color yellowSoft = Color(0x26F59E0B);
  static const Color warning = yellow;

  static const Color red = Color(0xFFDC2626); // Error
  static const Color redSoft = Color(0x26DC2626);
  static const Color error = red;
  static const Color danger = red;
  static const Color coral = red;

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0x262563EB);

  // ============================================================
  // 🪟 CARD SURFACES (soft shadows, not transparency)
  // ============================================================
  static const Color glass = Color(0xFFFFFFFF); // White card bg
  static const Color glassBorder = Color(0x14000000); // black @ 8% — border
  static const Color glassHover = Color(0xFFFFF4EB); // hover (primary 50)
  static const Color hairline = Color(0x0F000000); // ~6% black — divider

  // Topbar surface (sticky header)
  static const Color topbarBg = Color(0xFFFFFFFF);
  static const Color topbarBorder = Color(0x14000000); // 8% black

  // Bottom nav surface
  static const Color bottomNavBg = Color(0xFFFFFFFF);
  static const Color bottomNavBorder = Color(0x14000000); // 8% black

  // ============================================================
  // 🌈 GRADIENTS (helpers)
  // ============================================================
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary400],
  );

  static const LinearGradient tealGradient = orangeGradient; // back-compat

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary300],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0AFF6B00), // 4% orange
      Color(0x00FF6B00), // 0% orange
    ],
  );

  // ============================================================
  // 🎨 CARD DECORATION HELPERS
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 16, Color? tint}) {
    return BoxDecoration(
      color: tint ?? glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000), // 5% black — soft elevation
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration iconWrapDecoration(Color tint, {double radius = 12}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChipDecoration({Color? tint}) {
    return BoxDecoration(
      color: tint ?? surfaceAlt,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: glassBorder, width: 1),
    );
  }
}
