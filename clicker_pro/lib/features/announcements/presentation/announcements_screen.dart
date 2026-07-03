import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/motion.dart';
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
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 20,
          ),
        ),
        actions: [
          // Solid orange add tile from the .dc.html header (replaces the FAB).
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => CreateAnnouncementSheet.show(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: -8,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.onAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
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
                  itemBuilder: (_, i) => StaggeredList.item(
                    i,
                    _AnnouncementCard(
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
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: GestureDetector(
        onTap: onMarkRead,
        child: AnimatedOpacity(
          opacity: isExpired ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          // ClipRRect + Stack so the pinned card's 3px orange left rule can
          // sit flush against the rounded edge (.dc.html).
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (announcement.pinned) ...[
                            Icon(
                              Icons.push_pin,
                              color: AppColors.orange,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'PINNED',
                              style: TextStyle(
                                fontFamily: AppText.monoFontFamily,
                                fontSize: 9,
                                letterSpacing: 1.1,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            announcement.timeAgo,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.filmMuted,
                            ),
                          ),
                          if (canManage)
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'pin') onTogglePin();
                                if (v == 'delete') onDelete();
                              },
                              color: AppColors.surface,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                color: AppColors.filmMuted,
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
                      SizedBox(height: announcement.pinned ? 9 : 10),
                      Text(
                        announcement.title,
                        style: TextStyle(
                          fontFamily: AppText.brandFontFamily,
                          fontSize: announcement.pinned ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.film,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.55,
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
                                  : AppColors.filmMuted,
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
                                    : AppColors.filmMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.line(0.05)),
                          ),
                        ),
                        child: _readStatus(readCount, teamSize),
                      ),
                    ],
                  ),
                ),
                if (announcement.pinned)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: AppColors.orange),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Footer read state (.dc.html): "All read ✓" in green once everyone has
  /// seen it, otherwise a small colored-dot stack + "N of M read".
  Widget _readStatus(int read, int total) {
    if (read >= total && total > 0) {
      return Text(
        'All read ✓',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.green,
        ),
      );
    }

    final dotColors = [AppColors.gold, AppColors.purple, AppColors.green];
    final dots = read.clamp(0, 3);
    return Row(
      children: [
        if (dots > 0) ...[
          SizedBox(
            width: 20 + (dots - 1) * 13,
            height: 20,
            child: Stack(
              children: [
                for (var i = 0; i < dots; i++)
                  Positioned(
                    left: i * 13.0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColors[i % dotColors.length],
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
        ],
        Text(
          '$read of $total read',
          style: TextStyle(fontSize: 11, color: AppColors.filmMuted),
        ),
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
