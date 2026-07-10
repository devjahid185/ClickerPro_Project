// lib/features/announcements/presentation/web_announcements.dart
//
// Graphy7 — WEB-ONLY announcements (Graphy7 Design).
//
// A desktop announcement feed, rendered ONLY on wide web. The mobile
// announcements body is 100% untouched (AnnouncementsScreen routes here only
// when kIsWeb && width >= 900). Ported from the design source's
// "Announcements" screen (#12): a single ≤760px column, newest first, each card
// a white panel; pinned posts get a 3px orange left-edge bar + a "PINNED" pill.
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │  Announcements                               Post Update (⊕)  │
//   ├──────────────────────────────────────────────────────────────┤
//   │ ▎ [avatar] Owner · time                          📌 PINNED ⋮  │
//   │   Studio closed Aug 15                                        │
//   │   Body copy…                                                  │
//   │   ─────────────────────────────────────────────────────────  │
//   │   ● N of M read                                               │
//   └──────────────────────────────────────────────────────────────┘
//
// The reference card shows like/comment counters over mock data — the real
// backend has no such fields, so (per the no-fake-data rule) this keeps the
// honest footer the mobile card uses: the real "N of M read" status. All data
// comes from the same providers the mobile screen uses — no new business logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/announcement_providers.dart';
import '../domain/announcement.dart';

/// The wide-web announcements feed. Pure presentation over existing providers.
class WebAnnouncements extends ConsumerWidget {
  const WebAnnouncements({
    super.key,
    this.canManage = false,
    this.teamSize = 1,
    this.onPost,
    this.onTogglePin,
    this.onDelete,
    this.onMarkRead,
  });

  final bool canManage;

  /// Team size (members + owner) for the "N of M read" footer.
  final int teamSize;

  final VoidCallback? onPost;
  final void Function(Announcement a)? onTogglePin;
  final void Function(Announcement a)? onDelete;
  final void Function(Announcement a)? onMarkRead;

  /// The reference feed caps its column at 760px.
  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sortedAnnouncementsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(child: _Header(canManage: canManage, onPost: onPost)),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: async.when(
                loading: () => const Column(
                  children: [
                    _CardSkeleton(),
                    SizedBox(height: WebTheme.sp3),
                    _CardSkeleton(),
                  ],
                ),
                error: (_, _) => const _Message(
                  icon: Icons.campaign_outlined,
                  text: 'Could not load announcements.',
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _Message(
                      icon: Icons.campaign_outlined,
                      text: 'No announcements yet.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: WebTheme.sp3),
                        _AnnouncementCard(
                          announcement: items[i],
                          canManage: canManage,
                          teamSize: teamSize,
                          onTogglePin: onTogglePin == null
                              ? null
                              : () => onTogglePin!(items[i]),
                          onDelete: onDelete == null
                              ? null
                              : () => onDelete!(items[i]),
                          onMarkRead: onMarkRead == null
                              ? null
                              : () => onMarkRead!(items[i]),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({required this.canManage, required this.onPost});
  final bool canManage;
  final VoidCallback? onPost;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: WebTheme.ink,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Studio-wide updates for the whole team',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (canManage && onPost != null) ...[
          const SizedBox(width: WebTheme.sp4),
          WebHoverLift(
            onTap: onPost,
            borderRadius: WebTheme.rButton,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
              decoration: BoxDecoration(
                color: WebTheme.orange,
                borderRadius: BorderRadius.circular(WebTheme.rButton),
                boxShadow: [
                  BoxShadow(
                    color: WebTheme.orange.withValues(alpha: 0.42),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Post Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── CARD
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.canManage,
    required this.teamSize,
    required this.onTogglePin,
    required this.onDelete,
    required this.onMarkRead,
  });

  final Announcement announcement;
  final bool canManage;
  final int teamSize;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final expired = a.isExpired;

    return Opacity(
      opacity: expired ? 0.55 : 1.0,
      child: WebHoverLift(
        onTap: onMarkRead,
        borderRadius: WebTheme.rPanel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WebTheme.rPanel),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                decoration: BoxDecoration(
                  color: WebTheme.surface,
                  borderRadius: BorderRadius.circular(WebTheme.rPanel),
                  border: Border.all(color: WebTheme.hairline),
                  boxShadow: WebTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row: owner avatar + "Studio" role + time, pin pill.
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: WebTheme.orange.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              size: 19, color: WebTheme.orange),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Studio Announcement',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: WebTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a.timeAgo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: WebTheme.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (a.pinned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: WebTheme.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(WebTheme.rFull),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 13, color: WebTheme.orange),
                                SizedBox(width: 4),
                                Text(
                                  'PINNED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: WebTheme.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (canManage && (onTogglePin != null || onDelete != null))
                          _CardMenu(
                            pinned: a.pinned,
                            onTogglePin: onTogglePin,
                            onDelete: onDelete,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: WebTheme.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a.body,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: WebTheme.inkSoft,
                        height: 1.55,
                      ),
                    ),
                    if (a.expiresAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13,
                              color: expired ? WebTheme.danger : WebTheme.inkFaint),
                          const SizedBox(width: 5),
                          Text(
                            expired
                                ? 'Expired'
                                : 'Expires ${_formatExpiry(a.expiresAt!)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  expired ? WebTheme.danger : WebTheme.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: WebTheme.hairline),
                    const SizedBox(height: 12),
                    _ReadStatus(read: a.readCount, total: teamSize),
                  ],
                ),
              ),
              if (a.pinned)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: WebTheme.orange),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatExpiry(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'just now';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'in ${diff.inMinutes}m';
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.pinned,
    required this.onTogglePin,
    required this.onDelete,
  });

  final bool pinned;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'pin') onTogglePin?.call();
        if (v == 'delete') onDelete?.call();
      },
      color: WebTheme.surface,
      padding: EdgeInsets.zero,
      splashRadius: 18,
      icon: const Icon(Icons.more_horiz_rounded,
          color: WebTheme.inkFaint, size: 20),
      itemBuilder: (_) => [
        if (onTogglePin != null)
          PopupMenuItem(
            value: 'pin',
            child: Text(
              pinned ? 'Unpin' : 'Pin',
              style: const TextStyle(color: WebTheme.ink, fontSize: 13),
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete',
              style: TextStyle(color: WebTheme.danger, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

/// Footer read state — "All read ✓" once everyone's seen it, else a stacked
/// dot cluster + "N of M read". Mirrors the mobile card's honest footer.
class _ReadStatus extends StatelessWidget {
  const _ReadStatus({required this.read, required this.total});
  final int read;
  final int total;

  static const _dotColors = [
    WebTheme.amberDeep,
    WebTheme.info,
    WebTheme.success,
  ];

  @override
  Widget build(BuildContext context) {
    if (read >= total && total > 0) {
      return const Text(
        'All read ✓',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: WebTheme.success,
        ),
      );
    }
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
                        color: _dotColors[i % _dotColors.length],
                        border:
                            Border.all(color: WebTheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '$read of $total read',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: WebTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              WebShimmer(width: 38, height: 38, borderRadius: 11),
              SizedBox(width: 11),
              Expanded(child: WebShimmer(height: 14, borderRadius: 6)),
            ],
          ),
          SizedBox(height: 16),
          WebShimmer(width: 220, height: 15, borderRadius: 6),
          SizedBox(height: 10),
          WebShimmer(height: 12, borderRadius: 4),
          SizedBox(height: 8),
          WebShimmer(height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: Icon(icon, color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
