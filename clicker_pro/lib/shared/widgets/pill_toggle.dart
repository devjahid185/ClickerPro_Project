// lib/shared/widgets/pill_toggle.dart
//
// PillToggle — the on/off switch used across Graphy7, drawn to match the
// .dc.html mockup EXACTLY rather than Material's default Switch (which is
// taller, wider, and has different thumb proportions).
//
// HTML spec (both App.dc.html and App Dark.dc.html):
//   track  : 38 × 22, border-radius 11
//            ON  → primary accent fill (orange / lime)
//            OFF → muted track (light: #E0DDD5 · dark: inset)
//   thumb  : 18 × 18 white circle with a soft drop shadow
//            OFF → 2px from the left · ON → 18px from the left
//
// Animated: the thumb slides + the track colour cross-fades over 160ms.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// Null disables the toggle (dimmed, non-interactive).
  final ValueChanged<bool>? onChanged;

  static const double _trackW = 38;
  static const double _trackH = 22;
  static const double _thumb = 18;
  static const double _pad = 2;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    // OFF track: warm grey on the light theme, dark inset on Noir — both read
    // as "empty" against their card. ON track: the theme's primary accent.
    final Color trackOn = AppColors.orange;
    final Color trackOff = AppColors.isDark
        ? AppColors.voidElevated
        : const Color(0xFFE0DDD5);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: _trackW,
          height: _trackH,
          decoration: BoxDecoration(
            color: value ? trackOn : trackOff,
            borderRadius: BorderRadius.circular(_trackH / 2),
            // The Noir OFF track needs a faint hairline to separate from the
            // dark card; the light OFF track is opaque enough on its own.
            border: AppColors.isDark && !value
                ? Border.all(color: AppColors.line(0.10))
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _pad),
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
