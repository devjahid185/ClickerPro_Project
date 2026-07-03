// lib/shared/widgets/sync_status_sheet.dart
//
// Bottom sheet that surfaces the current outbox state. Tapping the
// top-bar SyncIndicator opens this sheet so the user can see what is
// pending or stuck and take action:
//
//   • Pending count summary (drained automatically as connectivity
//     allows; a "Retry now" button kicks the worker even if the
//     connectivity stream hasn't emitted recently).
//   • A list of `manual_retry` rows with per-item Retry / Discard
//     affordances. Each row shows the entity type + op + last error
//     so the user can decide whether the queued mutation is worth
//     keeping.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Outbox Worker Extensions". Validates Requirements 6.10, 10.5.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../features/bookings/application/booking_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class SyncStatusSheet extends ConsumerWidget {
  const SyncStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const SyncStatusSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final pendingAsync = ref.watch(_pendingProvider);
    final stuckAsync = ref.watch(_stuckProvider);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),
          Text(
            loc.sync_title,
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _PendingSummary(
            count: pendingAsync.value?.length ?? 0,
            onRetry: () => ref.read(outboxWorkerProvider).drainNow(),
            loc: loc,
          ),
          const SizedBox(height: 12),
          if ((stuckAsync.value ?? const []).isNotEmpty) ...[
            _SectionHeader(loc.sync_manual_retry_section),
            const SizedBox(height: 6),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: stuckAsync.value!.length,
                separatorBuilder: (_, _) => Container(
                  height: 1,
                  color: AppColors.line(0.04),
                ),
                itemBuilder: (_, i) {
                  final row = stuckAsync.value![i];
                  return _StuckRow(
                    row: row,
                    loc: loc,
                    onRetry: () async {
                      await db.outboxDao.requeueManualRetry(row.id);
                      await ref.read(outboxWorkerProvider).drainNow();
                    },
                    onDiscard: () => db.outboxDao.deleteItem(row.id),
                  );
                },
              ),
            ),
          ] else if (pendingAsync.value?.isEmpty ?? true) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.sync_everything_synced,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── Internals ───────────────────────────

final _pendingProvider = StreamProvider<List<OutboxRow>>(
  (ref) => ref.read(appDatabaseProvider).outboxDao.watchPending(),
);

final _stuckProvider = StreamProvider<List<OutboxRow>>(
  (ref) => ref.read(appDatabaseProvider).outboxDao.watchManualRetry(),
);

class _PendingSummary extends StatelessWidget {
  const _PendingSummary({
    required this.count,
    required this.onRetry,
    required this.loc,
  });

  final int count;
  final VoidCallback onRetry;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: AppColors.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.cloud_sync_outlined,
              size: 18,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? loc.sync_no_pending
                      : loc.sync_pending_count(count),
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? loc.sync_anything_will_sync
                      : loc.sync_will_sync_when_online,
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: onRetry,
              child: Text(
                loc.sync_retry,
                style: TextStyle(
                  color: AppColors.orange,
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppText.monoFontFamily,
          fontSize: 10.5,
          letterSpacing: 1.6,
          color: AppColors.gold.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StuckRow extends StatelessWidget {
  const _StuckRow({
    required this.row,
    required this.loc,
    required this.onRetry,
    required this.onDiscard,
  });

  final OutboxRow row;
  final AppLocalizations loc;
  final Future<void> Function() onRetry;
  final Future<void> Function() onDiscard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
            ),
            child: Text(
              loc.sync_stuck_label,
              style: TextStyle(
                color: AppColors.red,
                fontSize: 9.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.entityType} · ${row.op}',
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((row.lastError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    row.lastError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Retry',
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.orange,
              size: 20,
            ),
            onPressed: () => onRetry(),
          ),
          IconButton(
            tooltip: 'Discard',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
              size: 20,
            ),
            onPressed: () => onDiscard(),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.line(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
