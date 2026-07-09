// lib/shared/widgets/clicker_logo.dart
//
// Graphy7 brand mark — the orange G7 hexagon lockup (with the red/violet
// accent bubbles), supplied as a transparent PNG in assets/brand/. It reads
// cleanly on light, dark, or transparent backgrounds, so a single asset works
// across splash, login, settings, and the web sidebar.
//
// The widget keeps its historical name (`ClickerLogo`) so every existing call
// site picks up the new Graphy7 mark with no churn. Pair it with the
// [Graphy7Wordmark] helper when a text lockup is needed alongside the mark.

import 'package:flutter/material.dart';

/// The Graphy7 hexagon mark. [size] is the square edge in logical pixels; the
/// PNG's own aspect ratio is preserved (it is very slightly taller than wide).
class ClickerLogo extends StatelessWidget {
  const ClickerLogo({super.key, this.size = 64});

  final double size;

  static const String _asset = 'assets/brand/graphy7_mark.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The "Graphy7" wordmark — "Graphy" in the given [onColor] and the "7" in the
/// brand orange, matching the logo's colour split. Use on both light chrome
/// (pass an ink colour) and dark chrome (pass white).
class Graphy7Wordmark extends StatelessWidget {
  const Graphy7Wordmark({
    super.key,
    required this.onColor,
    this.fontSize = 22,
    this.accent = const Color(0xFFE2620E),
  });

  /// Colour for the "Graphy" portion (ink on light, white on dark chrome).
  final Color onColor;
  final double fontSize;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.03 * fontSize,
      height: 1.0,
      color: onColor,
    );
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Graphy'),
          TextSpan(text: '7', style: TextStyle(color: accent)),
        ],
      ),
      style: style,
    );
  }
}
