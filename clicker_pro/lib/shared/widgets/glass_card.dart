// lib/shared/widgets/glass_card.dart
//
// Graphy7 — Premium glassmorphism primitives (MOD-UI Phase 1).
//
// The existing `AppColors.glassCardDecoration` only paints a flat surface with
// a hairline border, which reads like a plain white card. These widgets add the
// real "frosted glass" treatment used across enterprise dashboards (Stripe /
// Linear class): a translucent gradient fill over a BackdropFilter blur, a
// gradient border that catches light at the top edge, layered depth shadows,
// and a subtle inner highlight.
//
// They are theme-aware (Sunset Studio light + Sunrise Pulse dark) and never
// touch business logic — pure presentation, safe to drop in anywhere.
//
//   GlassCard       — generic frosted container (replaces flat card surfaces)
//   GlassKpiCard    — KPI / stat tile with gradient icon chip + value
//   GlassEmptyState — elegant empty state for panels (icon + title + hint)
//
// Usage:
//   GlassCard(child: ...)
//   GlassKpiCard(label: 'Total Due', value: '৳0', icon: Icons.payments_outlined,
//                accent: AppColors.red)

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A frosted-glass container with gradient fill, light-catching border and
/// layered depth. The blur is real (BackdropFilter) so content behind it is
/// softened — pair it with the ambient backdrop in [WebShell] for the full
/// effect, but it also looks good over solid backgrounds.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.tint,
    this.onTap,
    this.blur = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional accent the glass is faintly washed with (e.g. card category).
  final Color? tint;

  /// When set, the card becomes tappable with an ink ripple.
  final VoidCallback? onTap;

  /// Backdrop blur sigma. 0 disables the BackdropFilter (cheaper) while keeping
  /// the gradient + border look.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    // Translucent gradient fill — brighter at the top-left so the surface reads
    // like glass catching light, fading to the theme surface tone.
    final fillTop = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.78);
    final fillBottom = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.55);

    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.90);
    final borderBottom = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.05);

    final tintWash = tint == null
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint!.withValues(alpha: isDark ? 0.16 : 0.10),
              tint!.withValues(alpha: 0.0),
            ],
          );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [fillTop, fillBottom],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [borderTop, borderBottom],
          ),
          width: 1.2,
        ),
      ),
      child: child,
    );

    // Faint accent wash on top of the fill, if a tint was given.
    if (tintWash != null) {
      content = Container(
        decoration: BoxDecoration(
          gradient: tintWash,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: content,
      );
    }

    // Tap affordance.
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Main soft drop shadow for elevation off the page.
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.10),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
          // Warm orange under-glow so cards feel part of the brand backdrop.
          BoxShadow(
            color: AppColors.orange.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 24,
            spreadRadius: -16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: content,
              )
            : content,
      ),
    );

    return shadowed;
  }
}

/// A premium KPI / stat tile: gradient icon chip, label, and a large value.
/// Designed for the dashboard metric grid but reusable anywhere a headline
/// number is shown.
class GlassKpiCard extends StatelessWidget {
  const GlassKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Drives the icon chip gradient and the faint card wash.
  final Color accent;
  final VoidCallback? onTap;

  /// Override for the value text colour (defaults to primary text).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.18) ?? accent,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: -3,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.onAccent, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Elegant empty state for panels — a soft gradient icon, a title and an
/// optional hint. Replaces bare "No bookings yet" text.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  c.withValues(alpha: 0.22),
                  c.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Icon(icon, color: c, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A [BoxBorder] that paints with a gradient, used by [GlassCard] for the
/// light-catching edge. Flutter has no built-in gradient border, so this draws
/// a stroked rounded rect with a gradient shader.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1.0});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    final radius = borderRadius ?? BorderRadius.zero;
    final outer = radius.toRRect(rect);
    // Inset by half the stroke so the border sits inside the bounds.
    final inner = outer.deflate(width / 2);
    canvas.drawRRect(inner, paint);
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}
