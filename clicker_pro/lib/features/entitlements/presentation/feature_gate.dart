import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../application/entitlement_providers.dart';
import 'paywall.dart';

/// Wraps a tappable feature entry point. When the feature is unlocked it just
/// renders [child] and forwards taps to [onTap]. When locked it overlays a
/// small PRO lock badge and intercepts taps to show the [Paywall].
///
/// Use for nav tiles / buttons that launch a gated feature:
/// ```
/// FeatureGate(
///   featureKey: Features.reminders,
///   featureName: 'Reminders',
///   onTap: () => Navigator.pushNamed(context, RouteNames.reminders),
///   child: _quickActionTile(...),
/// )
/// ```
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.featureName,
    required this.child,
    required this.onTap,
    this.showLockBadge = true,
  });

  final String featureKey;
  final String featureName;
  final Widget child;
  final VoidCallback onTap;
  final bool showLockBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(isFeatureUnlockedProvider(featureKey));

    if (unlocked) {
      return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Paywall.show(context, featureName: featureName),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Slightly dim the locked entry point so it reads as gated.
          Opacity(opacity: 0.85, child: child),
          if (showLockBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Guard for full-screen entry: call at the top of a gated screen's build,
/// or before navigating. Returns true if allowed; otherwise shows the paywall
/// and returns false.
bool ensureFeature(
  BuildContext context,
  WidgetRef ref, {
  required String featureKey,
  required String featureName,
}) {
  final unlocked = ref.read(isFeatureUnlockedProvider(featureKey));
  if (!unlocked) {
    Paywall.show(context, featureName: featureName);
  }
  return unlocked;
}
