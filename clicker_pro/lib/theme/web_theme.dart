// lib/theme/web_theme.dart
//
// Clicker Pro — WEB-ONLY design system.
//
// This file is imported ONLY by web widgets (WebShell, WebNavShell, web
// dashboard, calendar/booking polish). Mobile never touches it, so the phone
// UI is 100% unaffected — Heaven's requirement.
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │ STATUS: CLICKERPRO DESIGN — Signal Orange on a warm off-white canvas   │
// │         with a near-black sidebar. Values ported from the design source │
// │         `ClickerPro Web.dc.html` (Claude Design export).                │
// │                                                                        │
// │ Token NAMES are unchanged from the old placeholder (they are           │
// │ referenced ~170× across web widgets — renaming breaks callers). Only    │
// │ the hex VALUES were swapped, plus a few new sidebar-on-dark ink tokens  │
// │ (chromeInk*, sidebarDeep) for the dark chrome.                          │
// │                                                                        │
// │ Palette (from the .dc.html): accent #E2620E (Signal Orange, ramp       │
// │ F9A52E→B84E0A) · chrome #161513 near-black · page #FBFAF7 warm off-     │
// │ white · ink #1A1A18 · success #2F8F6B · teal #00898B · gold #C99A2E ·   │
// │ danger #B0453A · indigo #3541AF.                                        │
// └──────────────────────────────────────────────────────────────────────┘
//
// Everything here is `const` so it is free to read and the tree-shaker keeps
// only what each screen uses.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Web-only design tokens. Pure data + tiny helpers — no widgets, no state.
class WebTheme {
  WebTheme._();

  // ─────────────────────────────────────────────────────────── FONTS
  /// Monospace family for micro-labels / group headers (IBM Plex Mono in the
  /// design source). Resolved via google_fonts, so use this getter — a
  /// hardcoded `'IBM Plex Mono'` string will NOT match the runtime family.
  static final String? mono = GoogleFonts.ibmPlexMono().fontFamily;

  // ─────────────────────────────────────────────────────────── ACCENT
  // Signal Orange — the brand action colour (#E2620E, the most-used hue in
  // the design source). The ramp runs light → deep across the .dc.html.
  static const Color orange = Color(0xFFE2620E); // primary action
  static const Color orangeDark = Color(0xFFC0530B); // hover / pressed
  static const Color orangeDeep = Color(0xFFB84E0A); // deepest (gradients)
  static const Color orangeLight = Color(0xFFF4881C); // light ramp step
  static const Color orangeSoft = Color(0x14E2620E); // 8% tint fill

  // ─────────────────────────────────────────────────────────── CHROME
  // The sidebar chrome is near-black (#161513) in the design. `sage*` keeps
  // its old NAME (referenced widely) but now carries the warm-neutral chrome
  // scale used for muted text / hairlines on the LIGHT content side.
  static const Color sage = Color(0xFF3A3A36); // primary chrome ink
  static const Color sageDeep = Color(0xFF3A3A36); // headings on chrome
  static const Color sageDark = Color(0xFF1A1A18); // darkest — active text
  static const Color sageMid = Color(0xFF7A786F); // muted chrome text
  static const Color sageTint = Color(0xFFF4F3EF); // chip / panel fill
  static const Color sageTintSoft = Color(0xFFFAF9F6); // page wash, hover
  static const Color sageLine = Color(0xFFE8E6DF); // hairline on chrome

  // The near-black sidebar surface + the ink scale that reads ON it (light
  // text on dark chrome). New tokens — the old light-sidebar model had none.
  static const Color chrome = Color(0xFF161513); // sidebar surface (near-black)
  static const Color chromeInk = Color(0xFFEDEBE6); // primary text on chrome
  static const Color chromeInkMuted = Color(0xFF8C857C); // muted label on chrome
  static const Color chromeInkFaint = Color(0xFF6E6961); // faint group headers
  static const Color chromeLine = Color(0x14FFFFFF); // hairline on chrome (8% white)

  // Second accent — warm gold (was amber). From the design's #C99A2E.
  static const Color amber = Color(0xFFF9A52E); // bright amber (gradient hi)
  static const Color amberDeep = Color(0xFFC99A2E); // gold (badges, ratings)

  // Third accent — brick rose, from the design's #B0453A.
  static const Color rose = Color(0xFFB0453A);
  static const Color roseSoft = Color(0x14B0453A);

  // Supporting semantic colours — ported from the design's status hues so
  // chips/dots read as one system with the brand.
  static const Color success = Color(0xFF2F8F6B); // green
  static const Color successSoft = Color(0x142F8F6B);
  static const Color info = Color(0xFF3541AF); // indigo
  static const Color infoSoft = Color(0x143541AF);
  static const Color teal = Color(0xFF00898B); // teal accent
  static const Color tealSoft = Color(0x1400898B);
  static const Color warning = Color(0xFFC99A2E); // gold
  static const Color danger = Color(0xFFB0453A); // brick
  static const Color dangerSoft = Color(0x14B0453A);

  // ──────────────────────────────────────────────────────── SURFACES
  /// Page canvas — warm off-white (#FBFAF7) so cards lift with a warm cast.
  static const Color pageBg = Color(0xFFFBFAF7);
  static const Color pageBgDeep = Color(0xFFF4F3EF);

  /// Card / panel surface — pure white so cards lift cleanly off the warm
  /// off-white page (matches the design source, where every card is #fff).
  static const Color surface = Color(0xFFFFFFFF);

  /// Sidebar surface — near-black chrome (alias of [chrome]); `sidebarDeep`
  /// is a touch darker for the gradient foot.
  static const Color sidebar = chrome;
  static const Color sidebarDeep = Color(0xFF111010);

  // ───────────────────────────────────────────────────────────── INK
  /// Primary text — warm near-black (#1A1A18), matching the design.
  static const Color ink = Color(0xFF1A1A18);
  static const Color inkSoft = Color(0xFF3A3A36);
  static const Color inkMuted = Color(0xFF7A786F);
  static const Color inkFaint = Color(0xFF9A988F);

  // ─────────────────────────────────────────────────────────── HAIRLINES
  static const Color hairline = Color(0xFFEDEBE6);
  static const Color hairlineStrong = Color(0xFFE0DED7);

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

  /// Chrome blend — the near-black sidebar gradient (top → slightly darker
  /// foot). Used as the sidebar surface fill.
  static const LinearGradient sageBlend = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [chrome, sidebarDeep],
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
          color: Color(0x0F141412), // warm near-black, low alpha
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0A141412),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// A lifted shadow for hover / active states.
  static List<BoxShadow> get cardShadowHover => const [
        BoxShadow(
          color: Color(0x1FE2620E), // warm orange-tinted lift
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x14141412),
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
