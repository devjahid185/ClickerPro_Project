// lib/shared/widgets/clicker_logo.dart
//
// ClickerPro brand mark — the orange 6-blade camera aperture, drawn exactly
// from CLICKERPRO_DESIGN_SPEC.md §2 / logo.svg. Three orange tones, no black,
// transparent centre — reads on light, dark, or transparent backgrounds.
//
// Rendered with a CustomPainter (no flutter_svg dependency) so it stays crisp
// at any size. The paths are the spec's viewBox 0 0 200 200 coordinates,
// scaled to the requested size.

import 'package:flutter/material.dart';

class ClickerLogo extends StatelessWidget {
  const ClickerLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AperturePainter()),
    );
  }
}

class _AperturePainter extends CustomPainter {
  // Three orange tones from the spec (light → mid → deep).
  static const _t1 = Color(0xFFF9A52E);
  static const _t2 = Color(0xFFF4881C);
  static const _t3 = Color(0xFFEA7414);
  static const _t4 = Color(0xFFE2620E);

  // The six aperture blades — each an SVG path string on the 0..200 viewBox.
  // Colour order matches logo.svg exactly.
  static const List<(_Blade, Color)> _blades = [
    (
      _Blade('M100 14 A86 86 0 0 1 174.48 57 L119 100 L109.5 83.55 Z'),
      _t1,
    ),
    (
      _Blade('M174.48 57 A86 86 0 0 1 174.48 143 L109.5 116.45 L119 100 Z'),
      _t2,
    ),
    (
      _Blade('M174.48 143 A86 86 0 0 1 100 186 L90.5 116.45 L109.5 116.45 Z'),
      _t3,
    ),
    (
      _Blade('M100 186 A86 86 0 0 1 25.52 143 L81 100 L90.5 116.45 Z'),
      _t4,
    ),
    (
      _Blade('M25.52 143 A86 86 0 0 1 25.52 57 L90.5 83.55 L81 100 Z'),
      _t2,
    ),
    (
      _Blade('M25.52 57 A86 86 0 0 1 100 14 L109.5 83.55 L90.5 83.55 Z'),
      _t1,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    for (final (blade, color) in _blades) {
      paint.color = color;
      canvas.drawPath(blade.toPath(), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AperturePainter oldDelegate) => false;
}

/// A single aperture blade: two straight edges + one 86px-radius arc, matching
/// the spec's `M .. A 86 86 0 0 1 .. L .. L .. Z` blade paths.
class _Blade {
  const _Blade(this.raw);
  final String raw;

  Path toPath() {
    // Each blade is: moveTo(p0) · arcTo(p1, r=86, clockwise) · lineTo(p2) ·
    // lineTo(p3) · close. Parse the numbers out of the spec path string.
    final nums = RegExp(r'-?\d+\.?\d*')
        .allMatches(raw)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    // Layout: [x0,y0, rx,ry, xrot,large,sweep, x1,y1, x2,y2, x3,y3]
    final p0 = Offset(nums[0], nums[1]);
    final rx = nums[2];
    final large = nums[5] == 1;
    final sweep = nums[6] == 1;
    final p1 = Offset(nums[7], nums[8]);
    final p2 = Offset(nums[9], nums[10]);
    final p3 = Offset(nums[11], nums[12]);

    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..arcToPoint(
        p1,
        radius: Radius.circular(rx),
        largeArc: large,
        clockwise: sweep,
      )
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
  }
}
