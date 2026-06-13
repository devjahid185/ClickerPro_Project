// lib/shared/widgets/celebration.dart
//
// One-shot celebratory motion overlays — no packages, no controllers left
// running. Each helper inserts an OverlayEntry, plays a ~900ms animation,
// then removes itself.
//
//   • Celebration.confetti(context)  — booking saved 🎉
//   • Celebration.coinPop(context)   — payment received 🪙
//
// Both are fire-and-forget and safe to call right before a Navigator.pop.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class Celebration {
  const Celebration._();

  static void confetti(BuildContext context) =>
      _play(context, (t) => _ConfettiPainter(t));

  static void coinPop(BuildContext context) =>
      _play(context, (t) => _CoinPainter(t));

  static void _play(
    BuildContext context,
    CustomPainter Function(double t) painterFor,
  ) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 1100),
    );

    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => CustomPaint(
            painter: painterFor(controller.value),
            size: Size.infinite,
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }
}

/// Confetti burst from the top-centre, falling with a little spin.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static final _rng = math.Random(7);
  static final List<_Piece> _pieces = List.generate(28, (_) {
    return _Piece(
      angle: _rng.nextDouble() * 2 * math.pi,
      speed: 0.6 + _rng.nextDouble() * 0.9,
      spin: (_rng.nextDouble() - 0.5) * 8,
      color: [
        AppColors.orange,
        AppColors.gold,
        AppColors.green,
        AppColors.purple,
        AppColors.primary300,
      ][_rng.nextInt(5)],
      size: 5 + _rng.nextDouble() * 5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.28);
    final eased = Curves.easeOut.transform(t.clamp(0, 1));
    final fade = (1 - t).clamp(0.0, 1.0);

    for (final p in _pieces) {
      final dist = eased * size.height * 0.55 * p.speed;
      final dx = math.cos(p.angle) * dist * 0.7;
      final dy = math.sin(p.angle).abs() * dist + eased * 120; // gravity
      final pos = origin + Offset(dx, dy);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// A gold coin that pops up, spins (squash on the x-axis), and fades.
class _CoinPainter extends CustomPainter {
  _CoinPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final pop = Curves.elasticOut.transform(t.clamp(0, 1));
    final rise = -40.0 * Curves.easeOut.transform(t);
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    final r = 26.0 * pop;
    // Spin: squash horizontal radius with a sine so it looks like a flipping coin.
    final squash = (math.cos(t * 4 * math.pi)).abs().clamp(0.15, 1.0);

    canvas.save();
    canvas.translate(center.dx, center.dy + rise);
    canvas.scale(squash, 1.0);

    final body = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE7C76A), AppColors.gold, Color(0xFF96702D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
      ..color = AppColors.gold.withValues(alpha: fade);
    canvas.drawCircle(Offset.zero, r, body);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF7A5A20).withValues(alpha: fade);
    canvas.drawCircle(Offset.zero, r * 0.78, ring);
    canvas.restore();

    // ৳ symbol stays upright (drawn after the squash restore).
    final tp = TextPainter(
      text: TextSpan(
        text: '৳',
        style: TextStyle(
          color: const Color(0xFF5C4410).withValues(alpha: fade),
          fontSize: r * 0.9,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + rise - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.t != t;
}

class _Piece {
  _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.size,
  });
  final double angle;
  final double speed;
  final double spin;
  final Color color;
  final double size;
}
