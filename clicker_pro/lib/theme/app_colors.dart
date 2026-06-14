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
  // 🌗 THEME SWITCH
  //   `isDark` is flipped by app.dart from the persisted theme mode.
  //   The surface + text tokens below are GETTERS that read it, so the
  //   whole app (incl. custom-painted cards) recolors when dark mode is
  //   toggled — no per-screen rewrite needed.
  // ============================================================
  static bool isDark = false;

  // Deep Ocean dark surfaces (mirror AppTheme.oceanDeep).
  static const Color _dkBg = Color(0xFF0A1222);
  static const Color _dkSurface = Color(0xFF111B2E);
  static const Color _dkSurfaceAlt = Color(0xFF18253C);
  static const Color _dkInk = Color(0xFFEAF1FB);
  static const Color _dkInkDim = Color(0xFF9DB0CC);
  static const Color _dkInkMuted = Color(0xFF6B7E9C);
  static const Color _dkBorder = Color(0x1FFFFFFF); // white 12%
  static const Color _dkHairline = Color(0x14FFFFFF); // white 8%

  // ============================================================
  // ☀️ SURFACES — warm porcelain (light) / deep ocean (dark)
  // ============================================================
  static const Color _ltBg = Color(0xFFFAF8F5); // Warm porcelain background
  static const Color _ltSurface = Color(0xFFFFFFFF); // Card / surface
  static const Color _ltSurfaceAlt = Color(0xFFF5F1EA); // Warm linen surface

  static Color get appBg => isDark ? _dkBg : _ltBg;
  static Color get surface => isDark ? _dkSurface : _ltSurface;
  static Color get surfaceAlt => isDark ? _dkSurfaceAlt : _ltSurfaceAlt;

  // 🔁 Backward-compat: old dark "void" names now map to themed surfaces.
  static Color get voidBlack => appBg; // Main BG
  static Color get voidLight => surface; // Elevated surface
  static Color get voidElevated => surfaceAlt; // More elevated surface
  static Color get void3 => surfaceAlt;
  static Color get void2 => surface;

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
  static const Color gold = Color(0xFFB8893A); // champagne / lens gold
  static const Color goldSoft = Color(0x26B8893A);

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
  static const Color _ltFilm = Color(0xFF1C1917); // Warm ink — primary text
  static const Color _ltFilmDim = Color(0xFF78716C); // Warm stone — secondary
  static const Color _ltFilmMuted = Color(0xFFA8A29E); // tertiary

  static Color get film => isDark ? _dkInk : _ltFilm;
  static Color get filmDim => isDark ? _dkInkDim : _ltFilmDim;
  static Color get filmMuted => isDark ? _dkInkMuted : _ltFilmMuted;

  static Color get textPrimary => film;
  static Color get textSecondary => filmDim;
  static Color get textMuted => filmMuted;

  // Warm-neutral ramp (stone) — borders, dividers, fills
  static const Color gray50 = Color(0xFFFAFAF9);
  static const Color gray100 = Color(0xFFF5F5F4);
  static const Color gray200 = Color(0xFFE7E5E4);
  static const Color gray300 = Color(0xFFD6D3D1);
  static const Color gray400 = Color(0xFFA8A29E);
  static const Color gray500 = Color(0xFF78716C);
  static const Color gray600 = Color(0xFF57534E);
  static const Color gray700 = Color(0xFF44403C);
  static const Color gray800 = Color(0xFF292524);
  static const Color gray900 = Color(0xFF1C1917);

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
  /// Theme-aware subtle overlay used for hairline borders / faint fills.
  /// In light mode it's a faint black tint; in dark mode a faint white
  /// tint — so borders/dividers stay visible after dark mode is on. Pass
  /// the same alpha you'd have used with `Colors.black.withValues`.
  static Color line([double alpha = 0.08]) => isDark
      ? Colors.white.withValues(alpha: (alpha * 1.4).clamp(0.0, 1.0))
      : Colors.black.withValues(alpha: alpha);

  static Color get glass => isDark ? _dkSurface : _ltSurface; // card bg
  static Color get glassBorder => isDark ? _dkBorder : const Color(0x1A803500);
  static Color get glassHover => isDark ? _dkSurfaceAlt : const Color(0xFFFFF4EB);
  static Color get hairline => isDark ? _dkHairline : const Color(0x12803500);

  // Topbar surface (sticky header)
  static Color get topbarBg => isDark ? _dkBg : _ltSurface;
  static Color get topbarBorder => isDark ? _dkBorder : const Color(0x1A803500);

  // Bottom nav surface
  static Color get bottomNavBg => isDark ? _dkSurface : _ltSurface;
  static Color get bottomNavBorder =>
      isDark ? _dkBorder : const Color(0x1A803500);

  // ============================================================
  // 🌈 GRADIENTS (helpers)
  // ============================================================
  // Light catches the top-left, deepens to ember at the bottom —
  // reads richer than the old flat light-to-lighter ramp.
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8534), primary500, primary600],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient tealGradient = orangeGradient; // back-compat

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8534), primary500, primary700],
    stops: [0.0, 0.5, 1.0],
  );

  /// Champagne sheen for premium accents (badges, chief highlights).
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9B45C), gold, Color(0xFF96702D)],
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
      // Two-layer shadow: tight key light + wide warm ambient. The warm
      // tint in the ambient layer is what sells the luxury read.
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1C1917), // 4% warm ink — crisp key
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x14803500), // 8% warm umber — soft ambient
          blurRadius: 24,
          spreadRadius: -6,
          offset: Offset(0, 12),
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
