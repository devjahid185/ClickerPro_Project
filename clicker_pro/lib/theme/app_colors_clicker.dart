// lib/theme/app_colors_clicker.dart
//
// Graphy7 — "Graphy7" theme palette (the v-current DEFAULT).
//
// Extracted EXACTLY from CLICKERPRO_DESIGN_SPEC.md §1 (the finished, hand-tuned
// mockup). Do NOT substitute or "improve" these values — they are the source of
// truth. Warm editorial "paper" theme with a single confident orange accent.
//
// Same static API surface as AppColorsLight so the AppColors switch layer can
// delegate to either palette by the active theme.

import 'package:flutter/material.dart';

class AppColorsClicker {
  AppColorsClicker._();

  // ============================================================
  // 🔶 PRIMARY ACCENT — Brand Orange (#E2620E)
  // The ONLY interactive colour. Buttons, active states, key figures, logo.
  // ============================================================
  static const Color primary = Color(0xFFE2620E); // Brand orange
  static const Color primaryLight = Color(0xFFF89A2B); // Gradient partner
  static const Color primaryDark = Color(0xFFB84E0A); // Gradient end
  static const Color primaryTint = Color(0xFFFBEBDE); // Soft fill behind icons
  static const Color primarySoft = Color(0x1FE2620E); // ~12% for washes
  static const Color primaryGlow = Color(0x33E2620E); // ~20% for glows

  // Aliases mirroring AppColorsLight's terracotta/orange naming.
  static const Color terracotta = primary;
  static const Color terracottaLight = primaryLight;
  static const Color terracottaSoft = primarySoft;
  static const Color terracottaGlow = primaryGlow;
  static const Color orange = primary;
  static const Color orangeLight = primaryLight;
  static const Color orangeSoft = primarySoft;
  static const Color orangeGlow = primaryGlow;
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color signalOrange = primary;
  static const Color teal = primary;
  static const Color tealLight = primaryLight;
  static const Color tealSoft = primarySoft;
  static const Color tealGlow = primaryGlow;

  // ============================================================
  // ☀ï¸ SURFACES
  // ============================================================
  static const Color background = Color(0xFFFBFAF7); // App canvas (warm off-white)
  static const Color surface = Color(0xFFFFFFFF); // Cards, inputs, sheets
  static const Color surfaceAlt = Color(0xFFF4F3EF); // Phone body / muted panels

  // AppColorsLight-compatible aliases
  static const Color cream = background;
  static const Color creamDark = surfaceAlt;
  static const Color creamDeep = Color(0xFFEAE8E2); // slightly deeper muted panel
  static const Color glass = surface;

  // ============================================================
  // ðŸ“ TEXT
  // ============================================================
  static const Color textPrimary = Color(0xFF1A1A18); // Headings, primary text
  static const Color textSecondary = Color(0xFF3A3A36); // Body labels
  static const Color textMuted = Color(0xFF9A988F); // Meta, placeholders

  static const Color film = textPrimary;
  static const Color filmDim = textSecondary;
  static const Color filmMuted = textMuted;

  // ============================================================
  // 🧩 BORDERS / HAIRLINES
  // Spec: 1px solid rgba(0,0,0,0.06) hairline on most cards & inputs.
  // ============================================================
  static const Color glassBorder = Color(0x0F000000); // black @ ~6%
  static const Color glassHover = Color(0x0A000000); // black @ ~4%
  static const Color hairline = Color(0x14000000); // black @ ~8%

  // ============================================================
  // 🟢🔴 SEMANTIC / STATUS
  // ============================================================
  static const Color success = Color(0xFF2F8F6B); // Paid / delivered / positive
  static const Color green = success;
  static const Color greenSoft = Color(0x262F8F6B);

  static const Color warning = Color(0xFFC99A2E); // Pending, tentative dots
  static const Color gold = warning;
  static const Color goldSoft = Color(0x26C99A2E);
  static const Color yellow = warning;
  static const Color yellowSoft = Color(0x26C99A2E);

  static const Color danger = Color(0xFFC0392B); // Alerts, overdue, notif dot
  static const Color red = danger;
  static const Color rust = danger;
  static const Color redSoft = Color(0x26C0392B);
  static const Color rustSoft = redSoft;
  static const Color error = danger;
  static const Color coral = danger;

  // ============================================================
  // 🎨 DATA / ACCENT CARDS (Dashboard stat cards — intentional multi-colour)
  // Spec §1: keep these as-is; NOT part of the general button palette.
  // ============================================================
  static const Color infoTeal = Color(0xFF00898B); // "Upcoming" stat card
  static const Color infoBlue = Color(0xFF3541AF); // "Total" stat card
  static const Color accentViolet = Color(0xFF6D5BD0); // Secondary calendar marker
  static const Color sageData = Color(0xFF397564); // "Delivered" stat card

  // Secondary/tertiary aliases used by shared widgets.
  static const Color plum = accentViolet;
  static const Color plumSoft = Color(0x266D5BD0);
  static const Color purple = accentViolet;
  static const Color purpleSoft = plumSoft;
  static const Color brass = warning;
  static const Color indigo = infoBlue;
  static const Color indigoSoft = Color(0x263541AF);
  static const Color mint = success;

  // ============================================================
  // 🧭 TOPBAR / BOTTOM NAV
  // ============================================================
  static const Color topbarBg = background;
  static const Color topbarBorder = Color(0x33E2620E); // 20% orange
  static const Color bottomNavBg = surface;
  static const Color bottomNavBorder = Color(0x0F000000); // 6% black

  // ============================================================
  // 🌈 GRADIENTS
  // Spec: avatar / logo lockup use linear-gradient(135deg,#E2620E,#B84E0A).
  // ============================================================
  static const LinearGradient terracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  static const LinearGradient orangeGradient = terracottaGradient;
  static const LinearGradient tealGradient = terracottaGradient;

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // ============================================================
  // 🎨 DECORATION HELPERS
  // Spec: most cards are 1px hairline border, radius 18px, NOT shadow.
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 18, Color? tint}) {
    return BoxDecoration(
      color: tint ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 1),
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
      color: tint ?? primaryTint,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: glassBorder, width: 1),
    );
  }
}
