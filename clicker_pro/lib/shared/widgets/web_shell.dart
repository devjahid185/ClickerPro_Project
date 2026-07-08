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
