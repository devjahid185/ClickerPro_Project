// lib/features/announcements/presentation/web_announcements.dart
//
// Graphy7 — WEB-ONLY announcements (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 10, MOD-11).
//
// ≤860px column, per the handoff:
//   1. Intro line ("Pinned posts show on every member's dashboard…") +
//      orange "+ New Post" pill (managers only).
//   2. Pinned posts — dark #2B1D12 cards: gold "📌 PINNED" label + expiry
//      right, cream title, muted body, read-receipt dots + "N/M read".
//   3. Feed — white cards (hover: lift + orange border): author tile + meta,
//      title, body, footer read count.
//
// The reference shows comment counters over mock data — the real backend has
// none, so (per the no-fake-data rule) the footer keeps the honest
// "N of M read" the mobile card uses. Same providers as mobile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  /// The handoff caps this column at 860px.
  static const double _maxContentWidth = 860;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sortedAnnouncementsProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ScrollConfiguration(
          behavior:
              ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              WebEntrance(
                delay: const Duration(milliseconds: 50),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Pinned posts show on every member's dashboard "
                        'with read receipts.',
                        style: WebTheme.bodyStyle(
                            size: 12.5, color: WebTheme.inkMuted),
                      ),
                    ),
                    if (canManage && onPost != null) ...[
                      const SizedBox(width: 16),
                      _NewPostPill(onTap: onPost!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              async.when(
                loading: () => const Column(
                  children: [
                    _CardSkeleton(),
                    SizedBox(height: 12),
                    _CardSkeleton(),
                  ],
                ),
                error: (_, _) =>
                    const _Message(text: 'Could not load announcements.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const _Message(text: 'No announcements yet.');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        WebEntrance(
                          delay: Duration(
                              milliseconds: (60 * i).clamp(0, 420)),
                          offset: 8,
                          child: items[i].pinned
                              ? _PinnedCard(
                                  announcement: items[i],
                                  canManage: canManage,
                                  teamSize: teamSize,
                                  onTogglePin: _cb(onTogglePin, items[i]),
                                  onDelete: _cb(onDelete, items[i]),
                                  onMarkRead: _cb(onMarkRead, items[i]),
                                )
                              : _FeedCard(
                                  announcement: items[i],
                                  canManage: canManage,
                                  teamSize: teamSize,
                                  onTogglePin: _cb(onTogglePin, items[i]),
                                  onDelete: _cb(onDelete, items[i]),
                                  onMarkRead: _cb(onMarkRead, items[i]),
                                ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static VoidCallback? _cb(
      void Function(Announcement a)? fn, Announcement a) {
    return fn == null ? null : () => fn(a);
  }
}

/// "+ New Post" — orange pill with glow.
class _NewPostPill extends StatelessWidget {
  const _NewPostPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orangeDark : WebTheme.orange,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          boxShadow: WebTheme.buttonGlow,
        ),
        child: Text('+ New Post',
            style: WebTheme.bodyStyle(
                size: 13,
                weight: FontWeight.w700,
                color: WebTheme.chromeInk)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── PINNED (DARK)
class _PinnedCard extends StatelessWidget {
  const _PinnedCard({
    required this.announcement,
    required this.canManage,
    required this.teamSize,
    this.onTogglePin,
    this.onDelete,
    this.onMarkRead,
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
    return WebHoverLift(
      onTap: onMarkRead,
      borderRadius: WebTheme.rCard,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: WebTheme.chrome,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          boxShadow: WebTheme.darkCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📌 PINNED',
                    style: WebTheme.label(
                        size: 9, color: WebTheme.amber, tracking: 0.18)),
                const Spacer(),
                if (a.expiresAt != null)
                  Text(
                    a.isExpired
                        ? 'EXPIRED'
                        : 'EXPIRES ${DateFormat('d MMM').format(a.expiresAt!).toUpperCase()}',
                    style: WebTheme.label(
                        size: 9,
                        color: a.isExpired
                            ? WebTheme.danger
                            : WebTheme.chromeInkMuted,
                        tracking: 0.1),
                  ),
                if (canManage)
                  _CardMenu(
                    pinned: true,
                    dark: true,
                    onTogglePin: onTogglePin,
                    onDelete: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.title,
                style: WebTheme.bodyStyle(
                    size: 15,
                    weight: FontWeight.w700,
                    color: WebTheme.chromeInk)),
            const SizedBox(height: 6),
            Text(a.body,
                style: WebTheme.bodyStyle(
                    size: 12.5,
                    color: WebTheme.chromeInkMuted,
                    height: 1.55)),
            const SizedBox(height: 14),
            _ReadStatus(read: a.readCount, total: teamSize, dark: true),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── FEED (WHITE)
class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.announcement,
    required this.canManage,
    required this.teamSize,
    this.onTogglePin,
    this.onDelete,
    this.onMarkRead,
  });

  final Announcement announcement;
  final bool canManage;
  final int teamSize;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkRead;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final expired = a.isExpired;
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Opacity(
      opacity: expired ? 0.55 : 1.0,
      child: MouseRegion(
        cursor: widget.onMarkRead != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onMarkRead,
          child: AnimatedContainer(
            duration: noMotion ? Duration.zero : WebTheme.base,
            curve: WebTheme.ease,
            transform: Matrix4.translationValues(
                0, _hover && !noMotion ? -2 : 0, 0),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            decoration: BoxDecoration(
              color: WebTheme.surface,
              borderRadius: BorderRadius.circular(WebTheme.rCard),
              border: Border.all(
                  color: _hover ? WebTheme.orange : WebTheme.hairline),
              boxShadow: WebTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: WebTheme.orangeTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.campaign_rounded,
                            size: 15, color: WebTheme.orangeDeep),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Studio Announcement · ${a.timeAgo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                            size: 11.5, color: WebTheme.inkMuted),
                      ),
                    ),
                    if (a.expiresAt != null)
                      Text(
                        expired
                            ? 'EXPIRED'
                            : 'EXPIRES ${DateFormat('d MMM').format(a.expiresAt!).toUpperCase()}',
                        style: WebTheme.label(
                            size: 8.5,
                            color: expired
                                ? WebTheme.danger
                                : WebTheme.inkFaint,
                            tracking: 0.08),
                      ),
                    if (widget.canManage)
                      _CardMenu(
                        pinned: false,
                        dark: false,
                        onTogglePin: widget.onTogglePin,
                        onDelete: widget.onDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(a.title,
                    style: WebTheme.bodyStyle(
                        size: 14.5, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(a.body,
                    style: WebTheme.bodyStyle(
                        size: 12.5,
                        color: WebTheme.inkSoft,
                        height: 1.55)),
                const SizedBox(height: 12),
                _ReadStatus(
                    read: a.readCount,
                    total: widget.teamSize,
                    dark: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── PIECES
class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.pinned,
    required this.dark,
    required this.onTogglePin,
    required this.onDelete,
  });

  final bool pinned;
  final bool dark;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (onTogglePin == null && onDelete == null) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'pin') onTogglePin?.call();
        if (v == 'delete') onDelete?.call();
      },
      color: WebTheme.surface,
      padding: EdgeInsets.zero,
      splashRadius: 18,
      icon: Icon(Icons.more_horiz_rounded,
          color: dark ? WebTheme.chromeInkMuted : WebTheme.inkFaint,
          size: 20),
      itemBuilder: (_) => [
        if (onTogglePin != null)
          PopupMenuItem(
            value: 'pin',
            child: Text(
              pinned ? 'Unpin' : 'Pin',
              style: WebTheme.bodyStyle(size: 13),
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete',
              style: WebTheme.bodyStyle(size: 13, color: WebTheme.danger),
            ),
          ),
      ],
    );
  }
}

/// Read-receipt dots + "N/M read" (handoff footer). Real counts only.
class _ReadStatus extends StatelessWidget {
  const _ReadStatus({
    required this.read,
    required this.total,
    required this.dark,
  });

  final int read;
  final int total;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final dots = read.clamp(0, 3);
    final dim = total - read;
    final labelColor = dark ? WebTheme.chromeInkMuted : WebTheme.inkMuted;

    return Row(
      children: [
        for (var i = 0; i < dots; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: WebTheme.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (dim > 0)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: dark
                  ? WebTheme.chromeInkFaint.withValues(alpha: 0.5)
                  : WebTheme.tan,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          total > 0 && read >= total
              ? 'All read ✓'
              : '$read/$total read',
          style: WebTheme.label(
            size: 9,
            color: total > 0 && read >= total
                ? WebTheme.success
                : labelColor,
            tracking: 0.08,
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
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WebShimmer(width: 30, height: 30, borderRadius: 15),
              SizedBox(width: 11),
              Expanded(child: WebShimmer(height: 12, borderRadius: 6)),
            ],
          ),
          SizedBox(height: 14),
          WebShimmer(width: 220, height: 15, borderRadius: 6),
          SizedBox(height: 10),
          WebShimmer(height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: WebTheme.bodyStyle(size: 13, color: WebTheme.inkMuted),
        ),
      ),
    );
  }
}
