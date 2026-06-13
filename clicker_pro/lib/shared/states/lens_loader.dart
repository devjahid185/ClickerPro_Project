import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Premium camera-aperture loader. A ring of orange blades sweeps like a
/// lens iris closing, with a soft gold focus dot pulsing at the centre.
///
/// Drop-in replacement for the old `CircularProgressIndicator` — every
/// screen that already shows a `LensLoader` gets the photography motion for
/// free. 60fps, single AnimationController, no images.
class LensLoader extends StatefulWidget {
  const LensLoader({super.key, this.size = 28});
  final double size;

  @override
  State<LensLoader> createState() => _LensLoaderState();
}

class _LensLoaderState extends State<LensLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) =>
              CustomPaint(painter: _AperturePainter(_c.value)),
        ),
      ),
    );
  }
}

class _AperturePainter extends CustomPainter {
  _AperturePainter(this.t);

  /// 0..1 animation phase.
  final double t;

  static const int _blades = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Iris "breathing": the blades sweep in then out (ease in-out triangle).
    final breathe = (math.sin(t * 2 * math.pi) + 1) / 2; // 0..1
    final spin = t * 2 * math.pi;

    final bladePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, radius * 0.13);

    for (var i = 0; i < _blades; i++) {
      final base = (i / _blades) * 2 * math.pi + spin;
      // Each blade is a short arc near the rim; opacity staggers so the
      // ring reads as rotating rather than static.
      final phase = (breathe + i / _blades) % 1.0;
      bladePaint.color = AppColors.orange.withValues(
        alpha: 0.35 + 0.55 * phase,
      );
      final arcR = radius * (0.66 + 0.18 * breathe);
      final rect = Rect.fromCircle(center: center, radius: arcR);
      canvas.drawArc(rect, base, math.pi / _blades * 0.9, false, bladePaint);
    }

    // Centre focus dot — gold, gently pulsing.
    final dotPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55 + 0.4 * breathe);
    canvas.drawCircle(center, radius * (0.12 + 0.05 * breathe), dotPaint);
  }

  @override
  bool shouldRepaint(_AperturePainter old) => old.t != t;
}
