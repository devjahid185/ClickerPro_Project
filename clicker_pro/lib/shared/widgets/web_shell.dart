// lib/shared/widgets/web_shell.dart
//
// Web-only presentation shell. On mobile it is a pass-through (returns the
// child untouched) so the phone UI is NEVER affected.
//
// ClickerPro Design canvas: a subtle warm gradient with two faint glows for
// depth. The WebNavShell owns the sidebar + content layout on top of this
// backdrop. All colours read from WebTheme.
//
// Also exports [WebFormWidth] — a small helper that caps a form/column to a
// comfortable reading width and centres it on web (so login/register/onboarding
// content does not stretch edge-to-edge across a wide desktop window). On
// mobile it is a pass-through, so the phone layout is unchanged.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../theme/web_theme.dart';

class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: WebTheme.pageWash),
      child: Stack(
        children: [
          // Faint sage glow anchored top-left — pure decoration, no hit test.
          Positioned(
            top: -180,
            left: -160,
            child: IgnorePointer(
              child: Container(
                width: 620,
                height: 620,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      WebTheme.sage.withValues(alpha: 0.08),
                      WebTheme.sage.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // A second, warm orange glow bottom-right for brand balance.
          Positioned(
            bottom: -200,
            right: -180,
            child: IgnorePointer(
              child: Container(
                width: 560,
                height: 560,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      WebTheme.orange.withValues(alpha: 0.045),
                      WebTheme.orange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Caps [child] to [maxWidth] and centres it — but only on web. On mobile it
/// returns the child untouched, so phone screens (already narrower than
/// [maxWidth]) are 100% unaffected.
///
/// Use it to wrap the scrolling body of full-bleed auth/onboarding screens so
/// their fields, buttons and copy read as a tidy centred column on a wide
/// desktop window instead of stretching the full viewport width.
class WebFormWidth extends StatelessWidget {
  const WebFormWidth({
    super.key,
    required this.child,
    this.maxWidth = 440,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays [children] out in two columns on a wide web viewport, and in a single
/// stacked column everywhere else (narrow web + all mobile). Each item keeps
/// its own height; the grid just flows them left-to-right, two per row.
///
/// Use it for card/tile lists (team members, packages, gear) so they read as
/// a tidy two-up grid on desktop instead of one very wide row per item. On
/// mobile it is a plain [Column], so the phone layout is unchanged.
class WebTwoColumn extends StatelessWidget {
  const WebTwoColumn({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.wideBreakpoint = 720,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  /// Below this content width the list stays single-column.
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    // Single stacked column on mobile and on narrow web.
    Widget stacked() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i != 0) SizedBox(height: runSpacing),
              children[i],
            ],
          ],
        );

    if (!kIsWeb) return stacked();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w < wideBreakpoint) return stacked();
        final itemWidth = (w - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
