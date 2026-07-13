import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/broadcast_providers.dart';
import '../domain/broadcast.dart';

class BroadcastsScreen extends ConsumerWidget {
  const BroadcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(broadcastsProvider);

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
          'Platform Updates',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () async => ref.invalidate(broadcastsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: 'Failed to load platform updates',
                  onRetry: () => ref.invalidate(broadcastsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'No platform updates right now',
                      icon: Icons.campaign_outlined,
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => StaggeredList.item(
                    i,
                    _BroadcastCard(broadcast: items[i]),
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.broadcast});

  final Broadcast broadcast;

  Color _accent() {
    if (broadcast.isEmergency) return AppColors.red;
    if (broadcast.isImportant) return AppColors.orange;
    return AppColors.teal;
  }

  String _priorityLabel() {
    if (broadcast.isEmergency) return 'EMERGENCY';
    if (broadcast.isImportant) return 'IMPORTANT';
    return broadcast.type.toUpperCase();
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(broadcast.createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _open(BuildContext context) async {
    if (!broadcast.hasLink) return;
    final uri = Uri.tryParse(broadcast.link!);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GestureDetector(
        onTap: broadcast.hasLink ? () => _open(context) : null,
        child: Container(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (broadcast.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: broadcast.imageUrl!,
                  height: 160,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                  placeholder: (ctx, _) => Container(
                    height: 160,
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
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _priorityLabel(),
                            style: TextStyle(
                              fontFamily: AppText.sectionTitle.fontFamily,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(),
                          style: TextStyle(
                            fontFamily: AppText.sectionTitle.fontFamily,
                            fontSize: 10,
                            color: AppColors.filmDim.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            broadcast.isEmergency
                                ? Icons.warning_amber_rounded
                                : Icons.campaign_rounded,
                            color: accent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                broadcast.title,
                                style: TextStyle(
                                  color: AppColors.film,
                                  fontFamily: AppText.brandFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                broadcast.content,
                                style: TextStyle(
                                  color: AppColors.filmDim.withValues(
                                    alpha: 0.88,
                                  ),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (broadcast.hasLink) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: AppColors.line(0.06),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            broadcast.buttonLabel ?? 'Learn more',
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: accent,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
