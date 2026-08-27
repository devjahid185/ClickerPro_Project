// lib/theme/app_colors_noir.dart
//
// Graphy7 — "Noir" DARK theme palette.
//
// Extracted EXACTLY from CLICKERPRO_DARK_FLUTTER_SPEC.md §1 (the finished dark
// handoff in "Professional Modern Design dark/handoff"). Do NOT substitute or
// "improve" these values — they are the source of truth.
//
//   Aesthetic: near-black canvas · hairline white strokes · lime "glow" accent
//   · mono labels. No gradients on surfaces, no heavy shadows except the lime
//   glow on primary actions.
//
// Same static API surface as AppColorsClicker / AppColorsLight so the AppColors
// switch layer can delegate to this palette by the active theme.

import 'package:flutter/material.dart';

class AppColorsNoir {
  AppColorsNoir._();

  // ============================================================
  // 🖤 SURFACES (darkest → lightest)
  // EXACT values from Graphy7 App Dark.dc.html — the source-of-truth mockup.
  // Do NOT lift these toward charcoal; the handoff is near-pure-black by design.
  //   body #060708 · phone/page #0C0E11 · card #14171C · inset #1B1F26
  // ============================================================
  static const Color bg = Color(0xFF0C0E11); // app scaffold / phone background
  static const Color surface = Color(0xFF0C0E11); // phone/page surface, sheets
  static const Color card = Color(0xFF14171C); // cards, list tiles, inputs
  static const Color inset = Color(0xFF1B1F26); // nested chips, track bg

  // AppColors-compatible surface aliases
  static const Color background = bg;
  static const Color surfaceAlt = inset;
  static const Color cream = bg;
  static const Color creamDark = surfaceAlt;
  static const Color creamDeep = surface;
  static const Color glass = card;

  // ============================================================
  // 🟢 ACCENT & SEMANTIC — spec §1
  // ============================================================
  static const Color accent = Color(0xFFC8F252); // lime — primary, active, focus
  static const Color onAccent = Color(0xFF0E1206); // near-black text/icon ON lime
  static const Color day = Color(0xFFF5C044); // "Day shift" amber
  static const Color night = Color(0xFFA08CFF); // "Night shift" violet
  static const Color paid = Color(0xFF52E0A1); // paid / collected / positive
  static const Color due = Color(0xFFFF6E61); // due / cancelled / destructive

  // Accent tints (icon chips, selected pills) — spec §1
  static const Color accentTint = Color(0x1AC8F252); // rgba(200,242,82,0.10)
  static const Color nightTint = Color(0x24A08CFF);
  static const Color paidTint = Color(0x1F52E0A1);
  static const Color dueTint = Color(0x24FF6E61);

  // ── Primary-accent aliases (map the light theme's "orange" API to lime) ──
  static const Color primary = accent;
  static const Color primaryLight = accent;
  static const Color primaryDark = Color(0xFF9FC732); // darker lime for gradients
  static const Color primaryTint = accentTint;
  static const Color primarySoft = accentTint; // ~10% lime for washes
  static const Color primaryGlow = Color(0x33C8F252); // ~20% lime for glows

  static const Color terracotta = accent;
  static const Color terracottaLight = accent;
  static const Color terracottaSoft = accentTint;
  static const Color terracottaGlow = primaryGlow;
  static const Color orange = accent;
  static const Color orangeLight = accent;
  static const Color orangeSoft = accentTint;
  static const Color orangeGlow = primaryGlow;
  static const Color accentLight = accent;
  static const Color signalOrange = accent;
  static const Color teal = accent;
  static const Color tealLight = accent;
  static const Color tealSoft = accentTint;
  static const Color tealGlow = primaryGlow;

  // ============================================================
  // ðŸ“ TEXT — spec §1
  // ============================================================
  // Nudged the two dimmer tiers brighter than the raw handoff so labels and
  // secondary text stay legible on the near-black canvas (Heaven feedback:
  // "label/card/text more visible"). Primary text is already bright.
  static const Color text = Color(0xFFEDF1EA); // primary text
  static const Color muted = Color(0xFFB0B6C0); // secondary text (was #9BA1AB)
  static const Color faint = Color(0xFF828892); // labels/placeholders (was #5F6570)

  static const Color textPrimary = text;
  static const Color textSecondary = muted;
  static const Color textMuted = faint;
  static const Color film = text;
  static const Color filmDim = muted;
  static const Color filmMuted = faint;

  // ============================================================
  // 🧩 STROKES / HAIRLINES (semi-transparent white) — spec §1
  // ============================================================
  // Slightly stronger than the raw 0.07 handoff so cards separate from the
  // near-black canvas (Heaven feedback: "card more visible"). Still a hairline.
  static const Color stroke = Color(0x1FFFFFFF); // ~0.12 (was 0.07)
  static const Color strokeStrong = Color(0x2EFFFFFF); // ~0.18 — inputs, emphasis
  static const Color navStroke = Color(0x1FFFFFFF); // ~0.12 — bottom nav border

  // AppColors-compatible border aliases
  static const Color glassBorder = stroke;
  static const Color glassHover = Color(0x0AFFFFFF);
  static const Color hairline = strokeStrong;

  // ============================================================
  // 🟢🔴 SEMANTIC / STATUS (mapped onto the Noir semantic set)
  // ============================================================
  static const Color success = paid;
  static const Color green = paid;
  static const Color greenSoft = paidTint;

  static const Color warning = day;
  static const Color gold = day;
  static const Color goldSoft = Color(0x24F5C044);
  static const Color yellow = day;
  static const Color yellowSoft = goldSoft;
  static const Color brass = day;

  static const Color danger = due;
  static const Color red = due;
  static const Color rust = due;
  static const Color redSoft = dueTint;
  static const Color rustSoft = dueTint;
  static const Color error = due;
  static const Color coral = due;

  // ============================================================
  // 🎨 DATA / ACCENT CARDS
  // Noir keeps its own semantic set — map the light theme's data colours onto
  // the shift/semantic palette so multi-colour stat cards stay legible on dark.
  // ============================================================
  static const Color infoTeal = paid; // "Upcoming" stat card
  static const Color infoBlue = night; // "Total" stat card
  static const Color accentViolet = night; // secondary calendar marker
  static const Color sageData = accent; // "Delivered" stat card

  static const Color plum = night;
  static const Color plumSoft = nightTint;
  static const Color purple = night;
  static const Color purpleSoft = nightTint;
  static const Color indigo = night;
  static const Color indigoSoft = nightTint;
  static const Color mint = paid;

  // ============================================================
  // 🧭 TOPBAR / BOTTOM NAV — spec §3.10 (card bg + navStroke border)
  // ============================================================
  static const Color topbarBg = bg;
  static const Color topbarBorder = stroke;
  static const Color bottomNavBg = card;
  static const Color bottomNavBorder = navStroke;

  // ============================================================
  // 🌈 GRADIENTS
  // Spec forbids gradients on surfaces; keep a subtle lime lockup for the
  // avatar / drawer header only (the same slots the light theme gradients fill).
  // ============================================================
  static const LinearGradient terracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primaryDark],
  );
  static const LinearGradient orangeGradient = terracottaGradient;
  static const LinearGradient tealGradient = terracottaGradient;

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, surface],
  );

  // ============================================================
  // ✨ LIME GLOW — spec §1 (use on primary buttons & FAB)
  // ============================================================
  static List<BoxShadow> glow([
    double blur = 26,
    double y = 10,
    double a = 0.45,
  ]) => [
    BoxShadow(
      color: accent.withValues(alpha: a),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];

  // ============================================================
  // 🎨 DECORATION HELPERS
  // Spec §2 universal surface recipe: card bg + 1px hairline stroke, radius 16.
  // ============================================================
  static BoxDecoration glassCardDecoration({double radius = 16, Color? tint}) {
    return BoxDecoration(
      color: tint ?? card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: stroke, width: 1),
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
      color: tint ?? accentTint,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: strokeStrong, width: 1),
    );
  }
}
