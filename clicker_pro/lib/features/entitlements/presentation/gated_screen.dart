import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../application/entitlement_providers.dart';
import 'paywall.dart';

/// Route-level gate. Wrap a gated screen in the router so it renders the real
/// [child] only when the feature is unlocked; otherwise it shows a locked
/// placeholder with an Upgrade button. Keeps the gating in ONE place per route
/// instead of editing every screen.
///
/// ```
/// case RouteNames.reminders:
///   return MaterialPageRoute(
///     builder: (_) => const GatedScreen(
///       featureKey: Features.reminders,
///       featureName: 'Reminders',
///       child: RemindersScreen(),
///     ),
///   );
/// ```
class GatedScreen extends ConsumerWidget {
  const GatedScreen({
    super.key,
    required this.featureKey,
    required this.featureName,
    required this.child,
  });

  final String featureKey;
  final String featureName;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entitlementsProvider);

    // While loading or on error, be permissive (show the feature) — matches
    // the provider's allUnlocked fallback so a transient failure never locks.
    final unlocked = async.maybeWhen(
      data: (e) => e.isUnlocked(featureKey),
      orElse: () => true,
    );

    if (unlocked) return child;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          featureName,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.gold, size: 42),
              ),
              const SizedBox(height: 22),
              Text(
                '$featureName is a PRO feature',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Upgrade to PRO to unlock $featureName. '
                'Contact us to enable PRO on your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Paywall.show(context, featureName: featureName),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: const Text('Upgrade to PRO',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
