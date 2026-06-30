// lib/theme/web_theme.dart
//
// Clicker Pro — WEB-ONLY "Studio Sage" design system (v18).
//
// This file is imported ONLY by web widgets (WebShell, WebNavShell, web
// dashboard, calendar/booking polish). Mobile never touches it, so the phone
// UI is 100% unaffected — Heaven's requirement.
//
// Palette (Heaven's call): a calm sage-green CHROME (sidebar, nav, quiet
// surfaces) paired with Signal-Orange ACTION (primary CTAs, key highlights,
// the brand mark). Green keeps the app feeling professional and restful;
// orange keeps the brand identity loud where it matters. Crisp white content
// cards sit on a barely-tinted page so everything reads cleanly — Stripe /
// Linear-grade polish, not a flat beginner template.
//
// Everything here is `const` so it is free to read and the tree-shaker keeps
// only what each screen uses.

import 'package:flutter/material.dart';

/// Web-only design tokens. Pure data + tiny helpers — no widgets, no state.
class WebTheme {
  WebTheme._();

  // ───────────────────────────────────────────────────────── BRAND (ACTION)
  /// Signal Orange — the brand action colour (primary CTAs, key highlights,
  /// the brand mark). Used sparingly so it stays loud.
  static const Color orange = Color(0xFFFF6200);
  static const Color orangeDark = Color(0xFFE85700);
  static const Color orangeDeep = Color(0xFFC44900);
  static const Color orangeLight = Color(0xFFFF8534);
  static const Color orangeSoft = Color(0x14FF6200);

  // ─────────────────────────────────────────────────────── SAGE (CHROME)
  /// Studio Sage — the calm green chrome that drives the sidebar, nav, and
  /// quiet supporting surfaces. Deeper tones for ink-on-sage, soft tints for
  /// fills/washes.
  static const Color sage = Color(0xFF5B7B6A); // primary sage (icons, accents)
  static const Color sageDeep = Color(0xFF3E5A4B); // headings on sage chrome
  static const Color sageDark = Color(0xFF2C4438); // darkest — active text
  static const Color sageMid = Color(0xFF7C9686); // muted sage text
  static const Color sageTint = Color(0xFFE8F0EA); // sidebar / chip fill
  static const Color sageTintSoft = Color(0xFFF2F7F3); // page wash, hover
  static const Color sageLine = Color(0xFFD8E5DC); // sage hairline on chrome

  /// Amber / gold — the warm second accent (gradients, highlights, premium
  /// chips). Pairs with orange for the "sunset" blend.
  static const Color amber = Color(0xFFFFB020);
  static const Color amberDeep = Color(0xFFF59300);

  /// Rose — the soft third accent (subtle pops: avatars, secondary tags,
  /// chart series). Keeps the palette from being mono-orange.
  static const Color rose = Color(0xFFFF5A7A);
  static const Color roseSoft = Color(0x14FF5A7A);

  // Supporting semantic colours (kept calm so orange stays the hero).
  static const Color success = Color(0xFF1FA971);
  static const Color successSoft = Color(0x141FA971);
  static const Color info = Color(0xFF2E7BE5);
  static const Color infoSoft = Color(0x142E7BE5);
  static const Color warning = Color(0xFFEAA300);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0x14E5484D);

  // ──────────────────────────────────────────────────────── SURFACES
  /// Page canvas — a barely-sage off-white so white cards lift off it.
  static const Color pageBg = Color(0xFFF6FAF7);
  static const Color pageBgDeep = Color(0xFFEFF5F1);

  /// Card / panel surface — crisp white for content readability.
  static const Color surface = Color(0xFFFFFFFF);

  /// Sidebar surface — soft sage tint so it reads as calm green chrome,
  /// clearly distinct from the white content panel beside it.
  static const Color sidebar = Color(0xFFEAF1EC);
  static const Color sidebarDeep = Color(0xFFE2ECE5);

  // ───────────────────────────────────────────────────────────── INK
  /// Primary text — near-black with a faint cool/sage tint (never pure #000
  /// on web; softer is more readable and premium on the green-tinted page).
  static const Color ink = Color(0xFF161C18);
  static const Color inkSoft = Color(0xFF3D463F);
  static const Color inkMuted = Color(0xFF7A857D);
  static const Color inkFaint = Color(0xFFAAB4AC);

  // ─────────────────────────────────────────────────────────── HAIRLINES
  // Cool-neutral separators (faint sage) for crisp, calm divisions.
  static const Color hairline = Color(0xFFE7EDE9);
  static const Color hairlineStrong = Color(0xFFDAE3DD);

  // ─────────────────────────────────────────────────────────── GRADIENTS
  /// The signature sunset blend — orange → amber. Used on the brand mark,
  /// primary CTAs, and key action accents (the loud "Clicker Pro" identity).
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, amber],
  );

  /// A softer, three-stop sunset for large hero areas / headers.
  static const LinearGradient sunsetWide = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [orangeDeep, orange, amber],
  );

  /// Sage chrome blend — deep → primary sage. Used on the sidebar active pill
  /// and calm hero panels so the green chrome has depth without going loud.
  static const LinearGradient sageBlend = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sageDeep, sage],
  );

  /// Faint sage wash for the page backdrop (very subtle).
  static const LinearGradient pageWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pageBg, pageBgDeep],
  );

  // ──────────────────────────────────────────────────────────── SHADOWS
  /// Soft, cool-tinted elevation — depth without a harsh grey drop.
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F12241A),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0A12241A),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// A lifted shadow for hover / active states — a soft sage glow.
  static List<BoxShadow> get cardShadowHover => const [
        BoxShadow(
          color: Color(0x1F5B7B6A),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x1412241A),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  // ───────────────────────────────────────────────────────────── RADII
  static const double rCard = 16;
  static const double rPanel = 20;
  static const double rButton = 12;
  static const double rChip = 10;
  static const double rFull = 999;

  // ─────────────────────────────────────────────────────────── SPACING
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 24;
  static const double sp6 = 32;
  static const double sp7 = 48;

  // ─────────────────────────────────────────────────────────── MOTION
  /// Standard durations — tuned for a snappy-but-smooth feel.
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);

  /// House easing curve — gentle deceleration, never linear.
  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;

  // ───────────────────────────────────────────────────── STATUS COLOURS
  /// Map a booking status to a warm, legible accent (chips, dots, badges).
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return warning;
      case 'CONFIRMED':
        return info;
      case 'IN_PROGRESS':
        return orange;
      case 'SHOT_COMPLETE':
        return amberDeep;
      case 'DELIVERED':
      case 'COMPLETED':
      case 'SUCCESSFUL':
        return success;
      case 'CANCELLED':
        return danger;
      default:
        return inkMuted;
    }
  }
}
