// lib/widgets/metric_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PillType { day, night, done, cancel }

class MetricPill {
  final String text;
  final PillType type;
  const MetricPill(this.text, this.type);
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<MetricPill>? pills;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.pills,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.filmDim,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.08,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: color == AppColors.green
                          ? AppColors.green
                          : AppColors.film,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pills != null && pills!.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: pills!.map((p) => _Pill(pill: p)).toList(),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final MetricPill pill;
  const _Pill({required this.pill});

  ({Color bg, Color fg}) _colors() {
    switch (pill.type) {
      case PillType.day:
        return (
          bg: AppColors.yellow.withValues(alpha: 0.12),
          fg: AppColors.yellow,
        );
      case PillType.night:
        return (
          bg: AppColors.indigo.withValues(alpha: 0.12),
          fg: AppColors.indigo,
        );
      case PillType.done:
        return (
          bg: AppColors.green.withValues(alpha: 0.12),
          fg: AppColors.green,
        );
      case PillType.cancel:
        return (bg: AppColors.red.withValues(alpha: 0.12), fg: AppColors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            pill.text,
            style: TextStyle(
              fontFamily: 'monospace',
              color: c.fg,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.45,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
