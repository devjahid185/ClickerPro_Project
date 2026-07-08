// lib/shared/widgets/motion.dart
//
// Lightweight, dependency-free photography-flavoured motion primitives.
// All 60fps, all built on AnimatedSlide / AnimatedOpacity / AnimatedScale
// so there is no AnimationController bookkeeping at the call site.
//
//   • FadeUpIn  — staggered "develop" entrance (fade + slide up).
//   • TapScale  — press-to-shrink micro-interaction for cards / buttons.

import 'dart:async';

import 'package:flutter/material.dart';

/// Fades + slides a child up into place once, [order] frames after mount.
/// Use an increasing [order] down a column to get a staggered cascade,
/// like a print slowly developing.
class FadeUpIn extends StatefulWidget {
  const FadeUpIn({
    super.key,
    required this.child,
    this.order = 0,
    this.offset = 0.05,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;

  /// Stagger slot — the delay is `60ms + order * 70ms`.
  final int order;

  /// Initial downward offset as a fraction of the child's height.
  final double offset;

  final Duration duration;

  @override
  State<FadeUpIn> createState() => _FadeUpInState();
}

class _FadeUpInState extends State<FadeUpIn> {
  bool _shown = false;
  bool _scheduled = false;
  Timer? _revealTimer;

  void _scheduleReveal() {
    if (_scheduled) return;
    _scheduled = true;
    _revealTimer = Timer(
      Duration(milliseconds: 60 + widget.order * 70),
      () {
        if (mounted) setState(() => _shown = true);
      },
    );
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour the platform "remove animations" / reduce-motion setting — also
    // the right escape hatch for low-RAM phones where the staggered entrance
    // janks. When disabled we render the child immediately, fully in place.
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }
    _scheduleReveal();
    return AnimatedSlide(
      offset: _shown ? Offset.zero : Offset(0, widget.offset),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Wraps each child in a [FadeUpIn] with an automatically increasing [order],
/// producing a staggered "develop" cascade with zero per-call bookkeeping.
///
/// Drop-in for the children of a Column / ListView:
///
/// ```dart
/// Column(children: StaggeredList.wrap([
///   HeaderCard(),
///   StatRow(),
///   RecentList(),
/// ]));
/// ```
///
/// The stagger is capped at [maxOrder] so long lists don't get a sluggish
/// tail, and the whole thing collapses to plain children under reduce-motion
/// (FadeUpIn already honours that).
class StaggeredList {
  StaggeredList._();

  static List<Widget> wrap(
    List<Widget> children, {
    int startOrder = 0,
    int maxOrder = 8,
    double offset = 0.06,
  }) {
    return [
      for (var i = 0; i < children.length; i++)
        FadeUpIn(
          order: (startOrder + i).clamp(0, maxOrder),
          offset: offset,
          child: children[i],
        ),
    ];
  }

  /// Builder variant for `ListView.builder` / `SliverChildBuilderDelegate`:
  /// wraps the item at [index] with the right stagger order.
  static Widget item(int index, Widget child,
      {int maxOrder = 8, double offset = 0.06}) {
    return FadeUpIn(
      order: index.clamp(0, maxOrder),
      offset: offset,
      child: child,
    );
  }
}

/// Wraps a tappable surface so it gently shrinks while pressed — the
/// tactile "shutter press" feel on cards and primary buttons.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    // Reduce-motion / low-RAM: keep the tap working but drop the scale.
    if (MediaQuery.of(context).disableAnimations) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
