// lib/theme/app_colors_light.dart
//
// Graphy7 — Sunset Studio Light Theme (MOD-64)
// Warm cream & terracotta palette — NOT a color swap of dark.
// Same API surface as AppColors for easy theme-aware swapping.

import 'package:flutter/material.dart';

class AppColorsLight {
  AppColorsLight._();

  // ============================================================
  // ☀ï¸ SURFACE COLORS (Warm Creams)
  // ============================================================
  static const Color cream = Color(0xFFF4EBDD); // Main BG
  static const Color creamDark = Color(0xFFE8DCC8); // Elevated surface
  static const Color creamDeep = Color(0xFFDDD0BC); // Deepest surface

  // Backward-compat aliases mapping to AppColors equivalents
  static const Color voidBlack = cream;
  static const Color voidLight = creamDark;
  static const Color voidElevated = creamDeep;

  // ============================================================
  // 🔶 PRIMARY ACCENT — Signal Orange
  // Heaven: primary colour must be orange everywhere. The base used to be
  // clay terracotta (#C75A3C); it is now true Signal Orange so every alias
  // (orange / accent / signalOrange / gradients / topbar) reads orange.
  // ============================================================
  static const Color terracotta = Color(0xFFFF6200); // Signal Orange
  static const Color terracottaLight = Color(0xFFFF8534);
  static const Color terracottaSoft = Color(0x1FFF6200); // 12% opacity
  static const Color terracottaGlow = Color(0x33FF6200); // 20% opacity

  // Backward-compat aliases
  static const Color teal = terracotta;
  static const Color tealLight = terracottaLight;
  static const Color tealSoft = terracottaSoft;
  static const Color tealGlow = terracottaGlow;
  static const Color orange = terracotta;
  static const Color orangeLight = terracottaLight;
  static const Color orangeSoft = terracottaSoft;
  static const Color orangeGlow = terracottaGlow;
  static const Color accent = terracotta;
  static const Color accentLight = terracottaLight;
  static const Color signalOrange = terracotta;

  // ============================================================
  // 🟣 PLUM (Secondary)
  // ============================================================
  static const Color plum = Color(0xFF5C2E47);
  static const Color plumLight = Color(0xFF7D4567);
  static const Color plumSoft = Color(0x265C2E47);

  // Backward-compat
  static const Color gold = Color(0xFFB8893A);
  static const Color goldSoft = Color(0x26B8893A);

  // ============================================================
  // 🟤 BRASS (Tertiary)
  // ============================================================
  static const Color brass = Color(0xFFB8893A);
  static const Color brassLight = Color(0xFFD4A84A);
  static const Color brassSoft = Color(0x26B8893A);

  // Backward-compat
  static const Color purple = plum;
  static const Color purpleSoft = plumSoft;
  static const Color indigo = plum;
  static const Color indigoSoft = plumSoft;

  // ============================================================
  // 🌿 SAGE (Success)
  // ============================================================
  static const Color sage = Color(0xFF6B7F5C);
  static const Color sageLight = Color(0xFF8FA87C);
  static const Color sageSoft = Color(0x266B7F5C);

  // Backward-compat
  static const Color green = sage;
  static const Color greenSoft = sageSoft;
  static const Color success = sage;
  static const Color mint = sage;

  // ============================================================
  // 🔴 RUST (Error)
  // ============================================================
  static const Color rust = Color(0xFF8B3A2E);
  static const Color rustLight = Color(0xFFB04E3F);
  static const Color rustSoft = Color(0x268B3A2E);

  // Backward-compat
  static const Color red = rust;
  static const Color redSoft = rustSoft;
  static const Color error = rust;
  static const Color danger = rust;
  static const Color coral = rust;

  // ============================================================
  // 🟡 WARNING (Warm Yellow)
  // ============================================================
  static const Color yellow = Color(0xFFC99A2E);
  static const Color yellowSoft = Color(0x26C99A2E);
  static const Color warning = yellow;

  // ============================================================
  // ðŸ“ TEXT COLORS (Dark Browns on Light)
  // ============================================================
  static const Color textPrimary = Color(0xFF2D1810); // Dark brown
  static const Color textSecondary = Color(0xFF6B5A4E); // Medium brown
  static const Color textMuted = Color(0xFF9A8B7F); // Muted brown

  // Backward-compat aliases
  static const Color film = textPrimary;
  static const Color filmDim = textSecondary;
  static const Color filmMuted = textMuted;

  // ============================================================
  // 🪟 GLASS MORPHISM (Light variant — soft shadows, not transparency)
  // ============================================================
  static const Color glass = Color(0xFFFFFFFF); // White card bg
  static const Color glassBorder = Color(0x1A000000); // black @ 10%
  static const Color glassHover = Color(0x0A000000); // black @ 4%
  static const Color hairline = Color(0x14000000); // black @ 8%

  // Topbar surface
  static const Color topbarBg = Color(0xFFF4EBDD); // cream
  static const Color topbarBorder = Color(0x33FF6200); // 20% orange

  // Bottom nav surface
  static const Color bottomNavBg = Color(0xFFFAF6EF); // lighter cream
  static const Color bottomNavBorder = Color(0x14000000); // 8% black

  // ============================================================
  // 🌈 GRADIENTS
  // ============================================================
  static const LinearGradient terracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [terracotta, terracottaLight],
  );

  static const LinearGradient tealGradient = terracottaGradient;
  static const LinearGradient orangeGradient = terracottaGradient;

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [terracotta, creamDark],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // white
      Color(0x0A000000), // 4% black
    ],
  );

  // ============================================================
  // 🎨 GLASS DECORATION HELPERS
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 14, Color? tint}) {
    return BoxDecoration(
      color: tint ?? glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000), // 5% black
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration iconWrapDecoration(Color tint, {double radius = 10}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pillChipDecoration({Color? tint}) {
    return BoxDecoration(
      color: tint ?? const Color(0xFFF4EBDD),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: glassBorder, width: 1),
    );
  }
}
