// lib/features/admin/presentation/widgets/admin_floating_nav.dart
//
// The Graphy7 admin signature bottom navigation: a floating rounded pill bar
// inset from the screen edges, with a raised lime "+" FAB in the center. The
// FAB is a create action (compose a new broadcast) rather than a fourth tab,
// matching the design handoff's center-FAB pattern.
//
// Colours resolve through AppColors, which the PRO ADMIN app locks to the Noir
// (lime) palette — so "orange" here is the lime accent, "surface" the dark
// card, etc.

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

/// One tab in [AdminFloatingNav]. [label] is a short uppercase mono caption.
class AdminNavItem {
  const AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AdminFloatingNav extends StatelessWidget {
  const AdminFloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onComposeBroadcast,
    required this.items,
  }) : assert(items.length == 3, 'Design places the FAB between two pairs; '
            'this nav expects exactly 3 tabs.');

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onComposeBroadcast;
  final List<AdminNavItem> items;

  @override
  Widget build(BuildContext context) {
    // Sits above the system gesture inset so the pill never clips the nav bar.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14 + bottomInset),
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The pill bar itself.
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line(0.09)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _tab(0)),
                  Expanded(child: _tab(1)),
                  // Gap reserved for the raised FAB, centered in the pill.
                  const SizedBox(width: 64),
                  Expanded(child: _tab(2)),
                  // Empty slot mirrors the FAB gap so the three tabs stay
                  // balanced around the center rather than drifting left.
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
            // Raised lime FAB, lifted above the pill with a lime glow.
            Positioned(
              top: -16,
              child: _ComposeFab(onTap: onComposeBroadcast),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index) {
    final item = items[index];
    final selected = index == currentIndex;
    final color = selected ? AppColors.orange : AppColors.filmMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New broadcast',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.add, color: AppColors.onAccent, size: 28),
        ),
      ),
    );
  }
}
