// lib/shared/widgets/web_shell.dart
//
// Web-only presentation shell. On mobile it is a pass-through (returns the
// child untouched) so the phone UI is NEVER affected. On Flutter Web it
// paints an orange-tinted gradient backdrop with soft ambient glows and, on
// wide screens, frames the app inside a centered glassmorphism panel — the
// "AgrixAI" look, recoloured to the app's Signal Orange theme.
//
// It deliberately does not change any screen's widgets; it only wraps the
// MaterialApp output, so every route inherits the web styling for free.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

import '../../theme/app_colors.dart';

class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.child});

  final Widget child;

  /// Above this width we frame the app in a centered glass panel; below it
  /// (narrow browser / mobile-web) the app fills the viewport as usual.
  static const double _wideBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final isDark = AppColors.isDark;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wideBreakpoint;

    // Backdrop gradient — deep at the edges, lighter toward the middle, in
    // the active theme's tone (warm for Sunset, near-black for Sunrise).
    final bg = isDark
        ? const [Color(0xFF160B05), Color(0xFF241308), Color(0xFF160B05)]
        : const [Color(0xFFF6ECDD), Color(0xFFEADBC4), Color(0xFFF6ECDD)];

    final backdrop = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ),
      ),
      child: Stack(
        children: [
          // Ambient orange glow (top-right) and gold glow (bottom-left) —
          // the soft colour haze behind the glass.
          Positioned(
            top: -160,
            right: -120,
            child: _glow(AppColors.orange.withValues(alpha: 0.22), 460),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _glow(AppColors.gold.withValues(alpha: 0.16), 420),
          ),
          if (!isWide)
            // Narrow web: just the app over the backdrop.
            child
          else
            // Wide web: centered glass panel framing the app, phone-like width.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: _glassPanel(isDark, child),
                ),
              ),
            ),
        ],
      ),
    );

    return backdrop;
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _glassPanel(bool isDark, Widget child) {
    final glassFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                blurRadius: 50,
                spreadRadius: -10,
                offset: const Offset(0, 24),
              ),
              // Crisp top highlight for the "glass edge catching light" look.
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.10),
                blurRadius: 30,
                spreadRadius: -20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          // Round the app's own corners to sit inside the glass frame.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: child,
          ),
        ),
      ),
    );
  }
}
