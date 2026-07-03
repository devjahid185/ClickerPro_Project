// lib/features/chat/presentation/chat_screen.dart
//
// Team chat surface।  Two states:
//
//   1. No group yet → empty card with "Create team chat" CTA।  Backend's
//      `chatController.createTeamGroup` auto-names the group from the
//      caller's `fullName`, so we don't need a name input here।
//
//   2. Group exists → message thread + composer।  Self messages align
//      right (orange), others align left (glass)।  Optimistic send via
//      `ChatThreadController.send` shows the row immediately + reconciles
//      when the server echoes back।

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/chat_providers.dart';
import 'widgets/message_bubble.dart';
import '../../../theme/app_theme.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  /// Two-letter initials for the group avatar in the header.
  static String _groupInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final groupAsync = ref.watch(myGroupProvider);
    final group = groupAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        // White header strip over a hairline, per the .dc.html chat frame.
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: AppColors.line(0.05))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: group == null
            ? Text(
                loc.chat_title,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.02 * 18,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orangeSoft,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _groupInitials(group.name),
                      style: TextStyle(
                        color: AppColors.primary700,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.film,
                        fontFamily: AppText.brandFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: groupAsync.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => ErrorState(
          message: loc.chat_load_failed,
          onRetry: () => ref.invalidate(myGroupProvider),
        ),
        data: (group) {
          if (group == null) {
            return _NoGroupView(
              createGroup: () async {
                try {
                  await ref.read(chatRepositoryProvider).createGroup();
                  ref.invalidate(myGroupProvider);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.chat_create_failed)),
                  );
                }
              },
            );
          }
          return _ChatThreadView(groupId: group.id);
        },
      ),
    );
  }
}

class _NoGroupView extends StatelessWidget {
  const _NoGroupView({required this.createGroup});

  final Future<void> Function() createGroup;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return EmptyState(
      message: '${loc.chat_no_group_title}\n${loc.chat_no_group_subtitle}',
      icon: Icons.forum_outlined,
      actionLabel: loc.chat_create_group,
      onAction: createGroup,
    );
  }
}

class _ChatThreadView extends ConsumerStatefulWidget {
  const _ChatThreadView({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<_ChatThreadView> {
  final _composerCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;

  // Live chat: poll the thread every few seconds so new messages from other
  // members appear without a manual refresh. `poll()` is a silent refresh
  // (no loading flicker, skips while a send is in flight).
  static const _pollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    // Mark the thread seen on open (read receipts for other members).
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      ref.read(chatThreadControllerProvider(widget.groupId).notifier).poll();
      // Keep marking newly-arrived messages as seen while the thread is open.
      _markRead();
    });
  }

  void _markRead() {
    ref
        .read(chatRepositoryProvider)
        .markRead(widget.groupId)
        .catchError((_) {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _composerCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  /// Separator label for a calendar day — TODAY / YESTERDAY / "APR 12".
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'TODAY';
    if (day == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('MMM d').format(day).toUpperCase();
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context);
    final text = _composerCtl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _composerCtl.clear();
    try {
      await ref
          .read(chatThreadControllerProvider(widget.groupId).notifier)
          .send(text);
      // Auto-scroll to the bottom after the new bubble lands.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtl.hasClients) {
          _scrollCtl.animateTo(
            _scrollCtl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.chat_send_failed)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final selfId = ref.watch(currentUserProvider).value?.id;
    final selfRemoteId = ref.watch(currentUserProvider).value?.remoteId;
    final messages = ref.watch(chatThreadControllerProvider(widget.groupId));

    return Column(
      children: [
        Expanded(
          child: messages.when(
            loading: () => const Center(child: LensLoader()),
            error: (_, _) => ErrorState(
              message: loc.chat_thread_load_failed,
              onRetry: () => ref
                  .read(chatThreadControllerProvider(widget.groupId).notifier)
                  .refresh(),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      loc.chat_empty_thread,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.filmDim,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              // Flatten into rows with a day separator chip ("TODAY",
              // "YESTERDAY", "APR 12") whenever the calendar day changes.
              final rows = <Widget>[];
              DateTime? lastDay;
              for (final m in items) {
                final local = m.sentAt.toLocal();
                final day = DateTime(local.year, local.month, local.day);
                if (lastDay != day) {
                  rows.add(_DaySeparator(label: _dayLabel(day)));
                  lastDay = day;
                }
                final isSelf =
                    m.senderId == '_self' ||
                    (selfId != null && m.senderId == selfId) ||
                    (selfRemoteId != null && m.senderId == selfRemoteId);
                rows.add(
                  MessageBubble(message: m, isSelf: isSelf, lang: lang),
                );
              }
              return ListView(
                controller: _scrollCtl,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                children: rows,
              );
            },
          ),
        ),
        // Composer
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            8 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line(0.05))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _composerCtl,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_sending,
                    style: TextStyle(color: AppColors.film, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: loc.chat_message_hint,
                      hintStyle: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      // Borderless surfaceAlt pill per the .dc.html composer.
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.orange),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: _sending
                      ? const LensLoader(size: 16)
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Centered day chip ("TODAY") between message groups — mono micro-label
/// on a slightly darker pill, per the .dc.html thread.
class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.film.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 9,
              letterSpacing: 0.9,
              color: AppColors.filmMuted,
            ),
          ),
        ),
      ),
    );
  }
}
