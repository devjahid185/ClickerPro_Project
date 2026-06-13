import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../theme/app_colors.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.when(
      data: (online) => !online,
      loading: () => false,
      error: (_, _) => false,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axis: Axis.vertical,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: !isOffline
          ? const SizedBox(key: ValueKey('online'), height: 0)
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.yellow.withValues(alpha: 0.18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.yellow,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Offline — changes will sync when online',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.film,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
