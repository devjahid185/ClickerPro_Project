// lib/theme/web_theme.dart
//
// Clicker Pro — WEB-ONLY design system.
//
// This file is imported ONLY by web widgets (WebShell, WebNavShell, web
// dashboard, calendar/booking polish). Mobile never touches it, so the phone
// UI is 100% unaffected — Heaven's requirement.
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │ STATUS: SUNSET STUDIO WEB — warm cream canvas (#FBF6F0), white cards   │
// │         with warm sand borders, dark-brown sidebar (#2B1D12), Signal   │
// │         Orange (#EA5B0C) actions and Gold (#F5B02E) accents. Values    │
// │         ported from `design_handoff_clickerpro_web/` (ClickerPro       │
// │         Dashboard v2.dc.html — high-fidelity, recreate exactly).       │
// │                                                                        │
// │ Token NAMES are unchanged from the previous skin (referenced ~170×     │
// │ across web widgets — renaming breaks callers). Only the VALUES were    │
// │ swapped, plus new tokens the handoff needs: tint fills+borders, the    │
// │ NIGHT-shift purple ramp, gold tint, tan expense bar, Sora/DM Sans/     │
// │ Space Mono font handles, and the glow shadows.                         │
// └──────────────────────────────────────────────────────────────────────┘
//
// Everything here is `const` (or a cached getter) so it is free to read and
// the tree-shaker keeps only what each screen uses.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Web-only design tokens. Pure data + tiny helpers — no widgets, no state.
class WebTheme {
  WebTheme._();

  // ─────────────────────────────────────────────────────────── FONTS
  /// Monospace family for micro-labels / data (Space Mono in the handoff —
  /// always uppercase with 0.08–0.25em letter-spacing for labels). Resolved
  /// via google_fonts, so use this getter — a hardcoded `'Space Mono'` string
  /// will NOT match the runtime family.
  static final String? mono = GoogleFonts.spaceMono().fontFamily;

  /// Display family — headings, page titles, big numbers (Sora 600–800).
  static final String? display = GoogleFonts.sora().fontFamily;

  /// Body / UI family (DM Sans 400–700).
  static final String? body = GoogleFonts.dmSans().fontFamily;

  /// Bengali family — ৳ amounts and Bengali copy (Noto Sans Bengali).
  static final String? bengali = GoogleFonts.notoSansBengali().fontFamily;

  // ─────────────────────────────────────────────────────────── ACCENT
  // Signal Orange — the brand action colour (#EA5B0C in the handoff).
  static const Color orange = Color(0xFFEA5B0C); // primary action
  static const Color orangeDark = Color(0xFFC2410C); // hover / gradient end
  static const Color orangeDeep = Color(0xFFB8430A); // orange-tinted labels
  static const Color orangeLight = Color(0xFFF59E4C); // wordmark "Pro", light ramp
  static const Color orangeSoft = Color(0x14EA5B0C); // 8% tint fill (alpha)

  /// Solid orange tint surface + border (DAY chips, stat tiles, hover fills).
  static const Color orangeTint = Color(0xFFFFF3E8);
  static const Color orangeTintBorder = Color(0xFFF5C9A3);

  // ─────────────────────────────────────────────────────────── CHROME
  // `sage*` keeps its old NAME (referenced widely) but now carries the warm
  // brown ink scale used for muted text / hairlines on the LIGHT content side.
  static const Color sage = Color(0xFF6B5844); // secondary body text
  static const Color sageDeep = Color(0xFF2B1D12); // headings
  static const Color sageDark = Color(0xFF2B1D12); // darkest — active text
  static const Color sageMid = Color(0xFFA08469); // muted labels/captions
  static const Color sageTint = Color(0xFFFBF6F0); // nested row fill
  static const Color sageTintSoft = Color(0xFFFBF6F0); // page wash, hover
  static const Color sageLine = Color(0xFFEBDDCE); // hairline on light

  // The dark-brown sidebar surface + the ink scale that reads ON it.
  static const Color chrome = Color(0xFF2B1D12); // sidebar / dark cards
  static const Color chromeInk = Color(0xFFFFF6EE); // cream text on dark
  static const Color chromeInkMuted = Color(0xFFB99C82); // muted on dark
  static const Color chromeInkFaint = Color(0xFF8A6F55); // faint on dark
  static const Color chromeLine = Color(0x1AFFF6EE); // hairline on dark (10%)

  /// Avatar circle fill inside the sidebar profile ring.
  static const Color chromeAvatar = Color(0xFF3D2A1A);

  // Second accent — Gold (#F5B02E): sidebar accents, DAY shift, Chief card.
  static const Color amber = Color(0xFFF5B02E); // gold
  static const Color amberDeep = Color(0xFFC99414); // gold-tinted text
  static const Color amberText = Color(0xFFB8860B); // darker gold text
  static const Color amberTint = Color(0xFFFFF7E5); // gold tint bg
  static const Color amberTintBorder = Color(0xFFF2DFAE);

  // Third accent — danger red ramp.
  static const Color rose = Color(0xFFB23A3A); // red text alt
  static const Color roseSoft = Color(0x14B23A3A);

  // NIGHT-shift purple ramp — used for night chips/borders everywhere.
  static const Color night = Color(0xFF8B5CF6);
  static const Color nightText = Color(0xFF6D3FD4);
  static const Color nightTint = Color(0xFFF3EEFD);
  static const Color nightTintBorder = Color(0xFFD8C8F7);

  // Supporting semantic colours from the handoff.
  static const Color success = Color(0xFF1E9E6A); // paid, delivered, online
  static const Color successSoft = Color(0x141E9E6A);
  static const Color successTint = Color(0xFFE9F7F0);
  static const Color successTintBorder = Color(0xFFBCE3CF);
  static const Color info = Color(0xFF8B5CF6); // alias of night purple
  static const Color infoSoft = Color(0x148B5CF6);
  static const Color teal = Color(0xFF1E9E6A); // folded into success green
  static const Color tealSoft = Color(0x141E9E6A);
  static const Color warning = Color(0xFFC99414); // pending gold
  static const Color danger = Color(0xFFD64545); // dues, delete, logout
  static const Color dangerSoft = Color(0x14D64545);
  static const Color dangerTint = Color(0xFFFDECEC);
  static const Color dangerTintBorder = Color(0xFFF3BCBC);

  /// Tan — chart secondary/expense bars, toggle-off track.
  static const Color tan = Color(0xFFE3CDB4);

  /// Text on orange gradient surfaces (hero card, CTA labels/body).
  static const Color onOrangeLabel = Color(0xFFFFD9B8);
  static const Color onOrangeBody = Color(0xFFFFE4CC);

  // ──────────────────────────────────────────────────────── SURFACES
  /// Page canvas — warm cream (#FBF6F0); also nested row background.
  static const Color pageBg = Color(0xFFFBF6F0);
  static const Color pageBgDeep = Color(0xFFF5EDE3);

  /// Card / panel surface — pure white (every card in the handoff is #fff).
  static const Color surface = Color(0xFFFFFFFF);

  /// Sidebar surface — dark brown (alias of [chrome]); `sidebarDeep` is a
  /// touch darker for gradient feet.
  static const Color sidebar = chrome;
  static const Color sidebarDeep = Color(0xFF201509);

  // ───────────────────────────────────────────────────────────── INK
  /// Primary text — dark brown (#2B1D12), matching the handoff.
  static const Color ink = Color(0xFF2B1D12);
  static const Color inkSoft = Color(0xFF6B5844);
  static const Color inkMuted = Color(0xFFA08469);
  static const Color inkFaint = Color(0xFFB99C82);

  // ─────────────────────────────────────────────────────────── HAIRLINES
  /// Default card/input border.
  static const Color hairline = Color(0xFFEBDDCE);

  /// Borders INSIDE cards (rows, dividers) — slightly lighter.
  static const Color hairlineStrong = Color(0xFFF0E4D6);

  /// Alias with the handoff's name, for readability in new screens.
  static const Color innerLine = hairlineStrong;

  // ─────────────────────────────────────────────────────────── GRADIENTS
  /// Primary orange gradient — hero cards, CTAs (135° #EA5B0C → #C2410C).
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orangeDark],
  );

  /// Orange → gold — chart income bars, progress fills.
  static const LinearGradient sunsetWide = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [orange, amber],
  );

  /// Vertical orange → gold for bar charts (top → bottom).
  static const LinearGradient barGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orange, amber],
  );

  /// Gold gradient — the Chief card (135° #F5B02E → #E89A0C).
  static const LinearGradient goldBlend = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, Color(0xFFE89A0C)],
  );

  /// Chrome blend — the dark-brown sidebar surface fill.
  static const LinearGradient sageBlend = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [chrome, chrome],
  );

  /// Faint wash for the page backdrop (very subtle).
  static const LinearGradient pageWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pageBg, pageBg],
  );

  // ──────────────────────────────────────────────────────────── SHADOWS
  /// Card: 0 6px 20px rgba(43,29,18,0.06).
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F2B1D12),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ];

  /// Small card: 0 4px 14px rgba(43,29,18,0.05).
  static List<BoxShadow> get cardShadowSmall => const [
        BoxShadow(
          color: Color(0x0D2B1D12),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ];

  /// A lifted, orange-tinted shadow for hover / active states.
  static List<BoxShadow> get cardShadowHover => const [
        BoxShadow(
          color: Color(0x26EA5B0C),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ];

  /// Sidebar: 0 16px 44px rgba(43,29,18,0.22).
  static List<BoxShadow> get sidebarShadow => const [
        BoxShadow(
          color: Color(0x382B1D12),
          blurRadius: 44,
          offset: Offset(0, 16),
        ),
      ];

  /// Orange glow — hero card (0 16px 40px rgba(234,91,12,0.3)).
  static List<BoxShadow> get orangeGlow => const [
        BoxShadow(
          color: Color(0x4DEA5B0C),
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
      ];

  /// Orange button glow (0 6px 16px rgba(234,91,12,0.3)).
  static List<BoxShadow> get buttonGlow => const [
        BoxShadow(
          color: Color(0x4DEA5B0C),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  /// Gold glow — Chief card (0 14px 34px rgba(245,176,46,0.35)).
  static List<BoxShadow> get goldGlow => const [
        BoxShadow(
          color: Color(0x59F5B02E),
          blurRadius: 34,
          offset: Offset(0, 14),
        ),
      ];

  /// Dark card: 0 12px 32px rgba(43,29,18,0.25).
  static List<BoxShadow> get darkCardShadow => const [
        BoxShadow(
          color: Color(0x402B1D12),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ];

  // ───────────────────────────────────────────────────────────── RADII
  static const double rCard = 22; // cards
  static const double rPanel = 22; // large panels / dialogs
  static const double rSidebar = 30; // the sidebar shell
  static const double rTile = 18; // small cards / tiles
  static const double rRow = 14; // list rows
  static const double rButton = 12; // inputs (buttons are pills)
  static const double rChip = 10; // icon squares
  static const double rFull = 999; // chips / buttons / pills

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
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  /// House easing — cubic-bezier(0.2, 0.8, 0.2, 1) from the handoff.
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Overshoot pop — cubic-bezier(0.34, 1.56, 0.64, 1).
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  // ───────────────────────────────────────────────────── STATUS COLOURS
  /// Map a booking status to a legible accent (chips, dots, badges).
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return warning;
      case 'CONFIRMED':
        return nightText;
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

  // ───────────────────────────────────────────────────── TEXT HELPERS
  /// Space Mono micro-label: uppercase, wide tracking. Pass the size the
  /// handoff specifies (8–10px for labels).
  static TextStyle label({
    double size = 9,
    Color color = inkMuted,
    double tracking = 0.15,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        letterSpacing: size * tracking,
        fontWeight: weight,
        color: color,
        height: 1.2,
        decoration: TextDecoration.none,
      );

  /// Sora display style — headings and big numbers.
  static TextStyle displayStyle({
    double size = 17,
    Color color = ink,
    FontWeight weight = FontWeight.w700,
    double? height,
  }) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -size * 0.01,
        height: height ?? 1.2,
        decoration: TextDecoration.none,
      );

  /// DM Sans body style.
  static TextStyle bodyStyle({
    double size = 13,
    Color color = ink,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.35,
        decoration: TextDecoration.none,
      );
}
