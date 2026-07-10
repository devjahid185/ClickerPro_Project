import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../application/broadcast_providers.dart';
import '../application/dismissed_broadcasts_provider.dart';
import '../domain/broadcast.dart';

/// Compact platform-broadcast banner for the top of the dashboard. Shows the
/// most recent active broadcast; tapping it opens [Broadcast.link] (if any).
/// Renders nothing when there are no broadcasts. A small dot lets the user
/// page through multiple broadcasts.
class BroadcastBanner extends ConsumerStatefulWidget {
  const BroadcastBanner({super.key});

  @override
  ConsumerState<BroadcastBanner> createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends ConsumerState<BroadcastBanner> {
  int _index = 0;

  Future<void> _open(Broadcast b) async {
    if (!b.hasLink) return;
    final uri = Uri.tryParse(b.link!);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Color _accent(Broadcast b) {
    if (b.isEmergency) return AppColors.red;
    if (b.isImportant) return AppColors.orange;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(broadcastsProvider);
    final dismissed = ref.watch(dismissedBroadcastsProvider);
    return async.maybeWhen(
      data: (all) {
        // Drop broadcasts the user closed with (×) — they stay gone across
        // restarts (persisted in dismissedBroadcastsProvider).
        final items =
            all.where((b) => !dismissed.contains(b.id)).toList(growable: false);
        if (items.isEmpty) return const SizedBox.shrink();
        final i = _index.clamp(0, items.length - 1);
        final b = items[i];
        final accent = _accent(b);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: b.hasLink ? () => _open(b) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (b.imageUrl != null)
                    Image.network(
                      b.imageUrl!,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 130,
                          color: accent.withValues(alpha: 0.06),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        b.isEmergency
                            ? Icons.warning_amber_rounded
                            : Icons.campaign_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.film,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.filmDim.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          if (b.hasLink) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.buttonLabel ?? 'Learn more',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.open_in_new_rounded,
                                    color: accent, size: 13),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (items.length > 1) ...[
                      const SizedBox(width: 6),
                      Column(
                        children: [
                          _PagerButton(
                            icon: Icons.keyboard_arrow_up_rounded,
                            onTap: i > 0
                                ? () => setState(() => _index = i - 1)
                                : null,
                          ),
                          Text(
                            '${i + 1}/${items.length}',
                            style: TextStyle(
                              color: AppColors.filmMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _PagerButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            onTap: i < items.length - 1
                                ? () => setState(() => _index = i + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                    // Close (×): dismisses this broadcast for good. Reset the
                    // pager to the top so the next banner shows in place.
                    const SizedBox(width: 4),
                    _PagerButton(
                      icon: Icons.close_rounded,
                      onTap: () {
                        ref
                            .read(dismissedBroadcastsProvider.notifier)
                            .dismiss(b.id);
                        setState(() => _index = 0);
                      },
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Icon(
        icon,
        size: 18,
        color: onTap == null ? AppColors.filmMuted.withValues(alpha: 0.4) : AppColors.filmDim,
      ),
    );
  }
}
