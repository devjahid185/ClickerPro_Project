import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../profile/application/profile_controllers.dart';
import '../../settings/application/language_controller.dart';
import '../../team/application/team_providers.dart';
import '../application/announcement_providers.dart';
import '../domain/announcement.dart';
import 'create_announcement_sheet.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _lang() => ref
      .read(languageControllerProvider)
      .maybeWhen(data: (c) => c, orElse: () => 'en');

  String t(String key) => AppStrings.get(key, _lang());

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: Text(
          'Delete announcement',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(announcementListControllerProvider.notifier).remove(id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete announcement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sortedAnnouncementsProvider);
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final canManage =
        role != null && RolePolicy(role).can(Capability.createAnnouncement);
    // Real team size for the "N of M read" line: every member plus the owner.
    // Falls back to 1 (owner only) while the team list is still loading.
    final teamSize =
        (ref.watch(teamMembersProvider).valueOrNull?.length ?? 0) + 1;

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
          'Announcements',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () =>
            ref.read(announcementListControllerProvider.notifier).refresh(),
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
                  message: 'Failed to load announcements',
                  onRetry: () => ref
                      .read(announcementListControllerProvider.notifier)
                      .refresh(),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'No announcements yet',
                      icon: Icons.campaign_outlined,
                      actionLabel: canManage ? 'Create announcement' : null,
                      onAction: canManage
                          ? () => CreateAnnouncementSheet.show(context)
                          : null,
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _AnnouncementCard(
                    announcement: items[i],
                    canManage: canManage,
                    onTogglePin: () => ref
                        .read(announcementListControllerProvider.notifier)
                        .togglePin(items[i].id, items[i].pinned),
                    onDelete: () =>
                        _confirmAndDelete(context, ref, items[i].id),
                    onMarkRead: () => ref
                        .read(announcementListControllerProvider.notifier)
                        .markRead(items[i].id),
                    teamSize: teamSize,
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? async.maybeWhen(
              data: (items) => FloatingActionButton.extended(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                onPressed: () => CreateAnnouncementSheet.show(context),
                icon: const Icon(Icons.add),
                label: Text('New'),
              ),
              orElse: () => null,
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.canManage,
    required this.onTogglePin,
    required this.onDelete,
    required this.onMarkRead,
    required this.teamSize,
  });

  final Announcement announcement;
  final bool canManage;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;
  final int teamSize;

  @override
  Widget build(BuildContext context) {
    final isExpired = announcement.isExpired;
    final readCount = announcement.readCount;
    final preview = announcement.body.length > 120
        ? '${announcement.body.substring(0, 120)}...'
        : announcement.body;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: GestureDetector(
        onTap: onMarkRead,
        child: AnimatedOpacity(
          opacity: isExpired ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: announcement.pinned
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (announcement.pinned) ...[
                      Icon(
                        Icons.push_pin,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PINNED',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      announcement.timeAgo,
                      style: TextStyle(
                        fontFamily: AppText.sectionTitle.fontFamily,
                        fontSize: 10,
                        color: AppColors.filmDim.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (canManage)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'pin') onTogglePin();
                          if (v == 'delete') onDelete();
                        },
                        color: AppColors.voidLight,
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.filmDim.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(
                              announcement.pinned ? 'Unpin' : 'Pin',
                              style: TextStyle(color: AppColors.film),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.film,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.filmDim,
                    height: 1.5,
                  ),
                ),
                if (announcement.expiresAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isExpired
                            ? AppColors.red.withValues(alpha: 0.7)
                            : AppColors.filmDim.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'Expired'
                            : 'Expires ${_formatExpiry(announcement.expiresAt!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isExpired
                              ? AppColors.red.withValues(alpha: 0.7)
                              : AppColors.filmDim.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: AppColors.line(0.06),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\u{1F441}  $readCount of $teamSize read',
                      style: TextStyle(
                        fontFamily: AppText.sectionTitle.fontFamily,
                        fontSize: 10,
                        color: AppColors.filmDim.withValues(alpha: 0.6),
                      ),
                    ),
                    _buildReadPips(readCount, teamSize),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadPips(int read, int total) {
    final unread = total - read;
    return Row(
      children: [
        if (read > 0)
          Container(
            width: 16,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        if (unread > 0) ...[
          const SizedBox(width: 4),
          ...List.generate(
            unread.clamp(0, 5),
            (_) => Container(
              margin: const EdgeInsets.only(left: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatExpiry(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'just now';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'in ${diff.inMinutes}m';
  }
}
