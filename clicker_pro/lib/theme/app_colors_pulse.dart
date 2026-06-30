// lib/theme/app_colors_pulse.dart
//
// Clicker Pro v15 — Sunrise Pulse LIGHT theme colors
// Bright, crisp, high-energy: near-white surfaces + bold saturated orange.
// This is a LIGHT theme (v15 has no dark mode). It contrasts with Sunset
// Studio's warm cream by being cooler/whiter with punchier orange.
// Tighter corners (10–14 px), flat fills, crisp borders.

import 'package:flutter/material.dart';

class AppColorsPulse {
  AppColorsPulse._();

  // ============================================================
  // ⬜ SURFACES (bright, near-white with a faint cool tint)
  // ============================================================
  static const Color bg = Color(0xFFFFFFFF); // pure white background
  static const Color surface = Color(0xFFF7F8FA); // card / sheet (off-white)
  static const Color surfaceAlt = Color(0xFFEEF1F5); // elevated
  static const Color surfaceHigh = Color(0xFFE4E8EE); // highest elevation

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
  // 📝 TEXT (High-contrast on light)
  // ============================================================
  static const Color textPrimary = Color(0xFF14181F); // near-black ink
  static const Color textSecondary = Color(0xFF5A626E); // slate gray
  static const Color textMuted = Color(0xFF9AA1AC); // muted gray

  // Backward-compat aliases
  static const Color film = textPrimary;
  static const Color filmDim = textSecondary;
  static const Color filmMuted = textMuted;

  // ============================================================
  // 🔲 BORDERS (crisp on light — v15 Sunrise Pulse spec)
  // ============================================================
  static const Color border = Color(0xFFE0E4EA); // visible card border
  static const Color borderHighlight = Color(0xFFD0D5DD);
  static const Color hairline = Color(0x14000000); // black 8%
  static const Color glassBorder = Color(0xFFE0E4EA);

  // Glass (flat in Sunrise Pulse)
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
  static const Color topbarBg = bg; // white
  static const Color topbarBorder = border;
  static const Color bottomNavBg = Color(0xFFFFFFFF); // white nav
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
    colors: [primaryLight, primary],
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
