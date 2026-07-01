// lib/theme/web_theme.dart
//
// Clicker Pro — WEB-ONLY design system.
//
// This file is imported ONLY by web widgets (WebShell, WebNavShell, web
// dashboard, calendar/booking polish). Mobile never touches it, so the phone
// UI is 100% unaffected — Heaven's requirement.
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │ STATUS: NEUTRAL PLACEHOLDER — awaiting the new Claude Design theme.     │
// │                                                                        │
// │ The previous "Studio Sage" palette (sage-green chrome + Signal Orange) │
// │ has been retired. Every token below now resolves to a calm, neutral    │
// │ slate/grey scaffold so the web app reads as deliberately un-themed —   │
// │ a clean canvas to drop the new design onto.                            │
// │                                                                        │
// │ HOW TO APPLY THE NEW THEME (when the Claude Design tokens arrive):      │
// │   • Only swap the hex VALUES in the colour groups below.               │
// │   • Keep every token NAME (sage, sageTint, orange, amber, ink…) — they  │
// │     are referenced ~170× across web widgets; renaming breaks callers.   │
// │   • Structure tokens (radii, spacing, motion, shadows, gradients,       │
// │     statusColor) can stay as-is unless the new design dictates change.  │
// └──────────────────────────────────────────────────────────────────────┘
//
// Everything here is `const` so it is free to read and the tree-shaker keeps
// only what each screen uses.

import 'package:flutter/material.dart';

/// Web-only design tokens. Pure data + tiny helpers — no widgets, no state.
class WebTheme {
  WebTheme._();

  // ─────────────────────────────────────────────── ACCENT (placeholder)
  // Was Signal Orange. Now a neutral slate so the canvas stays un-branded
  // until the new design lands. Swap these for the new primary.
  static const Color orange = Color(0xFF64748B); // slate-500 (neutral accent)
  static const Color orangeDark = Color(0xFF475569); // slate-600
  static const Color orangeDeep = Color(0xFF334155); // slate-700
  static const Color orangeLight = Color(0xFF94A3B8); // slate-400
  static const Color orangeSoft = Color(0x1464748B);

  // ───────────────────────────────────────────── CHROME (placeholder)
  // Was Studio Sage green. Now neutral greys for the sidebar / quiet chrome.
  static const Color sage = Color(0xFF64748B); // primary chrome (icons, accents)
  static const Color sageDeep = Color(0xFF475569); // headings on chrome
  static const Color sageDark = Color(0xFF334155); // darkest — active text
  static const Color sageMid = Color(0xFF94A3B8); // muted chrome text
  static const Color sageTint = Color(0xFFEEF1F5); // sidebar / chip fill
  static const Color sageTintSoft = Color(0xFFF5F7FA); // page wash, hover
  static const Color sageLine = Color(0xFFE2E8F0); // hairline on chrome

  // Second accent (was amber/gold). Neutral for now.
  static const Color amber = Color(0xFF94A3B8);
  static const Color amberDeep = Color(0xFF64748B);

  // Third accent (was rose). Neutral for now.
  static const Color rose = Color(0xFF94A3B8);
  static const Color roseSoft = Color(0x1494A3B8);

  // Supporting semantic colours — kept functional (success/info/warn/danger
  // still need to read clearly), but muted so nothing competes with the
  // eventual brand accent.
  static const Color success = Color(0xFF1FA971);
  static const Color successSoft = Color(0x141FA971);
  static const Color info = Color(0xFF2E7BE5);
  static const Color infoSoft = Color(0x142E7BE5);
  static const Color warning = Color(0xFFEAA300);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0x14E5484D);

  // ──────────────────────────────────────────────────────── SURFACES
  /// Page canvas — a near-white neutral so white cards lift off it.
  static const Color pageBg = Color(0xFFF8FAFC); // slate-50
  static const Color pageBgDeep = Color(0xFFF1F5F9); // slate-100

  /// Card / panel surface — crisp white for content readability.
  static const Color surface = Color(0xFFFFFFFF);

  /// Sidebar surface — soft neutral tint, clearly distinct from white content.
  static const Color sidebar = Color(0xFFF1F5F9);
  static const Color sidebarDeep = Color(0xFFE9EFF5);

  // ───────────────────────────────────────────────────────────── INK
  /// Primary text — near-black with a faint cool tint (never pure #000 on
  /// web; softer is more readable and premium on the neutral page).
  static const Color ink = Color(0xFF1A1F26);
  static const Color inkSoft = Color(0xFF3E4651);
  static const Color inkMuted = Color(0xFF7A8694);
  static const Color inkFaint = Color(0xFFAAB4BF);

  // ─────────────────────────────────────────────────────────── HAIRLINES
  static const Color hairline = Color(0xFFEAEEF3);
  static const Color hairlineStrong = Color(0xFFDDE3EA);

  // ─────────────────────────────────────────────────────────── GRADIENTS
  /// Brand-mark / primary-CTA blend. Neutral slate for now — swap for the
  /// new design's signature gradient.
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, amber],
  );

  /// A wider three-stop version for large hero areas / headers.
  static const LinearGradient sunsetWide = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [orangeDeep, orange, amber],
  );

  /// Chrome blend — deep → primary. Used on the sidebar active pill and calm
  /// hero panels so the chrome has depth without going loud.
  static const LinearGradient sageBlend = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sageDeep, sage],
  );

  /// Faint wash for the page backdrop (very subtle).
  static const LinearGradient pageWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pageBg, pageBgDeep],
  );

  // ──────────────────────────────────────────────────────────── SHADOWS
  /// Soft, cool-tinted elevation — depth without a harsh grey drop.
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F1A2233),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0A1A2233),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// A lifted shadow for hover / active states.
  static List<BoxShadow> get cardShadowHover => const [
        BoxShadow(
          color: Color(0x1F64748B),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x141A2233),
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
  /// Map a booking status to a legible accent (chips, dots, badges).
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
