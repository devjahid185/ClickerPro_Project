// lib/shared/widgets/web_motion.dart
//
// Clicker Pro — WEB-ONLY motion primitives (v17, "Rich but smooth").
//
// A small kit of reusable, 60fps-friendly animation widgets used across the
// web shell and screens. Every one of them honours the user's reduce-motion
// preference: when MediaQuery.disableAnimations is true (OS setting OR the
// app's manual toggle, which app.dart folds into the same flag), the widgets
// render their final state instantly with no animation.
//
// Mobile never imports this file, so phone performance is untouched.

import 'package:flutter/material.dart';

import '../../theme/web_theme.dart';

/// True when motion should be suppressed (accessibility / low-end devices).
bool _noMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Fade + slide-up entrance. Plays once when the widget first mounts.
///
/// Used for cards, headers, and content blocks so screens "settle" in rather
/// than snapping. [delay] lets a parent stagger several of these.
class WebEntrance extends StatefulWidget {
  const WebEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
    this.duration,
  });

  final Widget child;
  final Duration delay;

  /// Starting vertical offset in logical pixels (slides up to 0).
  final double offset;
  final Duration? duration;

  @override
  State<WebEntrance> createState() => _WebEntranceState();
}

class _WebEntranceState extends State<WebEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? WebTheme.slow,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: WebTheme.ease);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offset / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: WebTheme.ease));

  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (_noMotion(context)) {
      _c.value = 1; // jump straight to the resting state
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Staggers a list of children with incremental entrance delays.
///
/// Returns a column by default; pass [builder] to control layout. Keeps the
/// stagger small (capped) so long lists don't feel sluggish.
class WebStagger extends StatelessWidget {
  const WebStagger({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 55),
    this.maxItems = 12,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration step;

  /// After this many items the delay stops growing — avoids a long tail.
  final int maxItems;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          WebEntrance(
            delay: step * (i.clamp(0, maxItems)),
            child: children[i],
          ),
      ],
    );
  }
}

/// A surface that lifts (shadow + slight scale) on hover and presses down on
/// tap. The web equivalent of a "tactile" card/button.
class WebHoverLift extends StatefulWidget {
  const WebHoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = WebTheme.rCard,
    this.liftScale = 1.012,
    this.enableShadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double liftScale;
  final bool enableShadow;

  @override
  State<WebHoverLift> createState() => _WebHoverLiftState();
}

class _WebHoverLiftState extends State<WebHoverLift> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final noMotion = _noMotion(context);
    final scale = noMotion
        ? 1.0
        : _pressed
            ? 0.985
            : _hover
                ? widget.liftScale
                : 1.0;

    final shadow = widget.enableShadow
        ? (_hover && !noMotion
            ? WebTheme.cardShadowHover
            : WebTheme.cardShadow)
        : const <BoxShadow>[];

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          transform: Matrix4.identity()..scaleByDouble(scale, scale, 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: shadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animated color/opacity highlight used by nav items, tabs, and chips so the
/// "active" state transitions smoothly instead of snapping.
class WebHoverHighlight extends StatefulWidget {
  const WebHoverHighlight({
    super.key,
    required this.builder,
    this.onTap,
    this.borderRadius = WebTheme.rButton,
  });

  /// Receives whether the pointer is currently hovering.
  final Widget Function(BuildContext context, bool hovering) builder;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<WebHoverHighlight> createState() => _WebHoverHighlightState();
}

class _WebHoverHighlightState extends State<WebHoverHighlight> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.builder(context, _hover),
      ),
    );
  }
}

/// Counts a number up from zero to [value] once on mount — the polished way a
/// KPI settles instead of snapping to its final figure. [builder] formats the
/// interpolated value however the caller likes (currency, plain int, suffix).
///
/// Honours reduce-motion: renders the final value instantly when motion is off.
/// When [value] changes (e.g. live data refresh) it eases from the old figure
/// to the new one, so streaming updates read as a smooth roll, not a jump.
class WebCountUp extends StatelessWidget {
  const WebCountUp({
    super.key,
    required this.value,
    required this.builder,
    this.duration,
    this.curve = WebTheme.easeInOut,
  });

  /// The target figure to count toward (the real, final value).
  final double value;

  /// Formats the current interpolated figure into a widget (usually a Text).
  final Widget Function(BuildContext context, double current) builder;
  final Duration? duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (_noMotion(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      // Keyed by the target so a new value animates from the current one.
      tween: Tween<double>(begin: 0, end: value),
      duration: duration ?? WebTheme.slow,
      curve: curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// A shimmering placeholder block — a soft sheen sweeps left→right across a
/// rounded surface while content loads. The premium alternative to a spinner
/// or a flat grey box.
///
/// Honours reduce-motion: falls back to a still, faint fill (no sweep) so the
/// skeleton still reads as "loading" without animating.
class WebShimmer extends StatefulWidget {
  const WebShimmer({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<WebShimmer> createState() => _WebShimmerState();
}

class _WebShimmerState extends State<WebShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_noMotion(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    if (_noMotion(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: WebTheme.sageTintSoft,
          borderRadius: radius,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Slide a bright band across the base; -1 → 2 keeps it fully off-screen
          // at each end for a clean, gapless loop.
          final t = _c.value * 3 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: WebTheme.sageTintSoft,
              gradient: LinearGradient(
                begin: Alignment(t - 1, 0),
                end: Alignment(t + 1, 0),
                colors: [
                  WebTheme.sageTintSoft,
                  WebTheme.sageTint,
                  WebTheme.hairline.withValues(alpha: 0.55),
                  WebTheme.sageTint,
                  WebTheme.sageTintSoft,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A page-transition builder for web routes: a quick fade + subtle slide.
/// Wire into PageRouteBuilder.transitionsBuilder.
Widget webPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  if (_noMotion(context)) return child;
  final curved = CurvedAnimation(parent: animation, curve: WebTheme.ease);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.02),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
