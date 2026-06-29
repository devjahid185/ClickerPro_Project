// lib/theme/app_colors_pulse.dart
//
// Clicker Pro v15 — Sunrise Pulse dark theme colors
// Bold, high-contrast, punchy consumer-app energy.
// No serif. Outfit for both headlines and body.
// Tighter corners (10–14 px), flat fills, 2 px high-contrast borders.

import 'package:flutter/material.dart';

class AppColorsPulse {
  AppColorsPulse._();

  // ============================================================
  // 🌑 SURFACES (deep graphite, not navy)
  // ============================================================
  static const Color bg = Color(0xFF0D0D0D); // true dark background
  static const Color surface = Color(0xFF1A1A1A); // card / sheet
  static const Color surfaceAlt = Color(0xFF242424); // elevated
  static const Color surfaceHigh = Color(0xFF2E2E2E); // highest elevation

  // Backward-compat aliases
  static const Color voidBlack = bg;
  static const Color voidLight = surface;
  static const Color voidElevated = surfaceAlt;
  static const Color void2 = surface;
  static const Color void3 = surfaceAlt;

  // ============================================================
  // 🔶 SUNRISE ORANGE (Primary CTA — punchy, saturated)
  // Heaven: primary must read orange (not red) everywhere. Pulse keeps a
  // brighter orange than Sunset but stays in the orange family.
  // ============================================================
  static const Color primary = Color(0xFFFF6A00); // vivid sunrise orange
  static const Color primaryLight = Color(0xFFFF8C3A); // lighter variant
  static const Color primarySoft = Color(0x26FF6A00); // 15% opacity
  static const Color primaryGlow = Color(0x40FF6A00); // 25% opacity

  // Backward-compat aliases
  static const Color orange = primary;
  static const Color orangeLight = primaryLight;
  static const Color orangeSoft = primarySoft;
  static const Color orangeGlow = primaryGlow;
  static const Color teal = primary;
  static const Color tealLight = primaryLight;
  static const Color tealSoft = primarySoft;
  static const Color tealGlow = primaryGlow;
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color signalOrange = primary;

  // ============================================================
  // 🟡 SUNRISE AMBER (Secondary accent)
  // ============================================================
  static const Color amber = Color(0xFFFFB800); // high-vis amber
  static const Color amberSoft = Color(0x26FFB800);
  static const Color gold = amber;
  static const Color goldSoft = amberSoft;

  // ============================================================
  // 📝 TEXT (High-contrast on dark)
  // ============================================================
  static const Color textPrimary = Color(0xFFF5F5F5); // near-white
  static const Color textSecondary = Color(0xFFAAAAAA); // medium gray
  static const Color textMuted = Color(0xFF666666); // muted

  // Backward-compat aliases
  static const Color film = textPrimary;
  static const Color filmDim = textSecondary;
  static const Color filmMuted = textMuted;

  // ============================================================
  // 🔲 BORDERS (2px high-contrast — v15 Sunrise Pulse spec)
  // ============================================================
  static const Color border = Color(0xFF333333); // visible card border
  static const Color borderHighlight = Color(0xFF444444);
  static const Color hairline = Color(0x33FFFFFF); // white 20%
  static const Color glassBorder = Color(0xFF333333);

  // Glass (flat in Sunrise Pulse — no transparency)
  static const Color glass = surface;
  static const Color glassHover = surfaceAlt;

  // ============================================================
  // 🟣 PURPLE / INFO (unused in Pulse but kept for compat)
  // ============================================================
  static const Color purple = Color(0xFF9B59FF);
  static const Color purpleSoft = Color(0x269B59FF);
  static const Color indigo = Color(0xFF4488FF);
  static const Color indigoSoft = Color(0x264488FF);
  static const Color info = indigo;
  static const Color infoSoft = indigoSoft;

  // ============================================================
  // 🟢🔴 SEMANTIC / STATUS
  // ============================================================
  static const Color green = Color(0xFF22C55E);
  static const Color greenSoft = Color(0x2622C55E);
  static const Color success = green;
  static const Color mint = green;

  static const Color yellow = Color(0xFFFFB800);
  static const Color yellowSoft = Color(0x26FFB800);
  static const Color warning = yellow;

  static const Color red = Color(0xFFEF4444);
  static const Color redSoft = Color(0x26EF4444);
  static const Color error = red;
  static const Color danger = red;
  static const Color coral = red;

  // ============================================================
  // 🏠 NAV / TOPBAR
  // ============================================================
  static const Color topbarBg = bg;
  static const Color topbarBorder = border;
  static const Color bottomNavBg = surface;
  static const Color bottomNavBorder = border;

  // ============================================================
  // 🌈 GRADIENTS (flat-leaning for Sunrise Pulse)
  // ============================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
    stops: [0.0, 1.0],
  );

  static const LinearGradient tealGradient = primaryGradient;
  static const LinearGradient orangeGradient = primaryGradient;

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, Color(0xFFCC9400)],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0AFF6A00), // 4% orange
      Color(0x00FF6A00), // 0%
    ],
  );

  // ============================================================
  // 🎨 DECORATION HELPERS
  // ============================================================

  /// Flat card with 2px high-contrast border — Sunrise Pulse signature.
  static BoxDecoration glassCardDecoration({double radius = 12, Color? tint}) {
    return BoxDecoration(
      color: tint ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 2),
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
      color: tint ?? surfaceAlt,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: border, width: 2),
    );
  }
}
