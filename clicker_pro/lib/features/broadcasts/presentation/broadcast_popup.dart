// lib/features/broadcasts/presentation/broadcast_popup.dart
//
// Premium modal popup for admin broadcasts (created from the Admin Panel).
//
// Behaviour (per spec):
//   • Shown when the user opens the app and an UNSEEN broadcast exists.
//   • Auto-closes after 10 seconds — a slim progress bar shows the countdown.
//   • Can be closed any time with the (×) button.
//   • Each broadcast is shown once; seen ids persist in KvStore.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/storage/kv_store.dart';
import '../../../theme/app_colors.dart';
import '../application/broadcast_providers.dart';
import '../domain/broadcast.dart';

/// How long the popup stays before auto-closing.
const Duration kBroadcastPopupDuration = Duration(seconds: 10);

String _today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// Presents every active broadcast the user hasn't yet hit its daily cap for,
/// one after another. Each broadcast may pop up `timesPerDay` times per day
/// (set per broadcast in the admin panel); counts reset at midnight and are
/// tracked per broadcast id in KvStore. Safe to call on every app open — any
/// network error silently no-ops.
Future<void> showBroadcastPopupIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  List<Broadcast> items;
  try {
    items = await ref.read(broadcastsProvider.future);
  } catch (_) {
    return;
  }
  if (items.isEmpty) return;

  final kv = KvStore();
  final counts = await _readCounts(kv);
  final today = _today();

  // Newest first; show each broadcast still under its per-day cap.
  final due = items
      .where((b) => b.id.isNotEmpty)
      .where((b) {
        final rec = counts[b.id];
        final shownToday = (rec != null && rec['date'] == today)
            ? (rec['count'] as int? ?? 0)
            : 0;
        return shownToday < b.timesPerDay;
      })
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  if (due.isEmpty) return;

  for (final broadcast in due) {
    if (!context.mounted) return;

    // Count it BEFORE showing so a crash/hot-restart can't loop forever.
    final rec = counts[broadcast.id];
    final shownToday = (rec != null && rec['date'] == today)
        ? (rec['count'] as int? ?? 0)
        : 0;
    counts[broadcast.id] = {'date': today, 'count': shownToday + 1};
    await _writeCounts(kv, counts);
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Broadcast',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _BroadcastPopupDialog(broadcast: broadcast),
      transitionBuilder: (context, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Per-broadcast daily show counts: `{ id: {date: 'yyyy-mm-dd', count: n} }`.
Future<Map<String, Map<String, dynamic>>> _readCounts(KvStore kv) async {
  final raw = await kv.readString(KvKeys.broadcastShowCounts) ?? '';
  if (raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  } catch (_) {
    return {};
  }
}

Future<void> _writeCounts(
  KvStore kv,
  Map<String, Map<String, dynamic>> counts,
) async {
  // Drop stale (not-today) entries so storage doesn't grow unbounded.
  final today = _today();
  counts.removeWhere((_, v) => v['date'] != today);
  await kv.writeString(KvKeys.broadcastShowCounts, jsonEncode(counts));
}

class _BroadcastPopupDialog extends StatefulWidget {
  const _BroadcastPopupDialog({required this.broadcast});

  final Broadcast broadcast;

  @override
  State<_BroadcastPopupDialog> createState() => _BroadcastPopupDialogState();
}

class _BroadcastPopupDialogState extends State<_BroadcastPopupDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown;

  @override
  void initState() {
    super.initState();
    _countdown =
        AnimationController(vsync: this, duration: kBroadcastPopupDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              Navigator.of(context).maybePop();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  Color get _accent {
    final b = widget.broadcast;
    if (b.isEmergency) return AppColors.red;
    if (b.isImportant) return AppColors.orange;
    return AppColors.teal;
  }

  Future<void> _openLink() async {
    final link = widget.broadcast.link;
    if (link == null) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.broadcast;
    final accent = _accent;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.voidElevated,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: ONLY the banner image (if one is set), with the
                  // (×) on top. No accent band, no ANNOUNCEMENT badge. ──
                  if (b.imageUrl != null && b.imageUrl!.trim().isNotEmpty)
                    Stack(
                      children: [
                        Image.network(
                          b.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // Cap height so very tall images don't dominate, but
                          // let normal banners show fully.
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _CloseButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ],
                    ),

                  // ── Body ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      // When there's no image header, leave room for the (×)
                      // and add a close button inline at the top-right.
                      b.imageUrl != null && b.imageUrl!.trim().isNotEmpty
                          ? 18
                          : 14,
                      22,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inline close button when there is no image header.
                        if (!(b.imageUrl != null && b.imageUrl!.trim().isNotEmpty))
                          Align(
                            alignment: Alignment.centerRight,
                            child: _CloseButton(
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        Text(
                          b.title,
                          style: TextStyle(
                            color: AppColors.film,
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b.content,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.filmDim.withValues(alpha: 0.95),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        if (b.hasLink) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _openLink,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                b.buttonLabel ?? 'Learn more',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Auto-close countdown bar ──
                  AnimatedBuilder(
                    animation: _countdown,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: 1 - _countdown.value,
                        minHeight: 3,
                        backgroundColor: accent.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation(
                          accent.withValues(alpha: 0.85),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
