// lib/features/bookings/presentation/widgets/detail_section.dart
//
// Shared section scaffold used by every block of the booking detail
// screen — header card, client info, schedule, package, etc. Keeps the
// visual contract (Cormorant Garamond title, soft hairline border, glass
// card surface) in one place so the screen stays declarative and
// regressions stay localized.

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';


/// Glass-surface card with a small uppercase title and a body slot.
///
/// `actions` render in the title row (e.g. an Edit affordance for the
/// header section). The widget is intentionally `Padding` + `Container`
/// rather than `Card` so it inherits the dark luxury lens contract
/// (glass tint, 1-px hairline) instead of Material's default elevation.
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.padding,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.glassCardDecoration(),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      // Design (.dc.html): section headers are mono uppercase
                      // micro-labels in muted grey, not a gold serif caption.
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 9.5,
                      letterSpacing: 1.4,
                      color: AppColors.filmMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Single label/value row used by the header / schedule / client info
/// blocks. `value` is rendered in white; missing values collapse to an
/// em-dash so the layout stays stable across rows.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback? onTap;

  /// Optional action widget at the end of the row (e.g. the call button
  /// on the client phone row).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = (value == null || value!.isEmpty) ? '—' : value!;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: AppColors.filmDim.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.filmMuted.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resolvedValue,
              style: TextStyle(
                // film (ink) — `Colors.white` disappeared on the light
                // theme's white card surface.
                color: valueColor ?? AppColors.film,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

/// Small round call-action button used next to phone rows. Launches the
/// dialer immediately via the provided callback.
class CallIconButton extends StatelessWidget {
  const CallIconButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.call_rounded, size: 16, color: AppColors.green),
        ),
      ),
    );
  }
}
