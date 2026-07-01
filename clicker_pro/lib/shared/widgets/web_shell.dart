// lib/shared/widgets/web_shell.dart
//
// Web-only presentation shell. On mobile it is a pass-through (returns the
// child untouched) so the phone UI is NEVER affected.
//
// Neutral placeholder (awaiting the new Claude Design web theme): the page
// canvas is a subtle neutral gradient with two faint glows for depth — calm and
// un-branded until the new palette lands. The WebNavShell owns the sidebar +
// content layout on top of this backdrop. All colours read from WebTheme.

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
