// lib/shared/widgets/sync_indicator.dart
//
// Top-bar sync status dot — three observable states (Req 6.10):
//   • synced  — soft green dot
//   • pending — yellow dot
//   • error   — red dot
//
// Tapping the dot opens the [SyncStatusSheet] so the user can inspect
// pending items, kick a manual retry, or discard stuck rows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/outbox_worker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'sync_status_sheet.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    final status = statusAsync.maybeWhen(
      data: (s) => s,
      orElse: () => SyncStatus.synced,
    );

    final color = switch (status) {
      SyncStatus.synced => AppColors.green,
      SyncStatus.pending => AppColors.yellow,
      SyncStatus.error => AppColors.red,
    };
    final loc = AppLocalizations.of(context);
    final tooltip = switch (status) {
      SyncStatus.synced => loc.sync_synced,
      SyncStatus.pending => loc.sync_pending_tap,
      SyncStatus.error => loc.sync_error_tap,
    };

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => SyncStatusSheet.show(context),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: status == SyncStatus.synced ? 7 : 9,
            height: status == SyncStatus.synced ? 7 : 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: status == SyncStatus.synced
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
