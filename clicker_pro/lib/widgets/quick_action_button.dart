// lib/widgets/quick_action_button.dart
//
// Pixel-exact match to Dashboard.html v6.2 demo:
//   - Padding: 12 vertical, 6 horizontal
//   - Border-radius: 14px, gradient background
//   - Icon wrap: 36×36, 10px radius
//   - Icon: 18px
//   - Label: mono 10px, uppercase, letter-spacing 0.04em, film-dim
//   - Gap between icon and label: 7px

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? AppColors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(height: 7),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.filmDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4, // 0.04em on 10px
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
