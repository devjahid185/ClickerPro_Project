// lib/features/chat/presentation/web_chat.dart
//
// Graphy7 — WEB-ONLY team chat (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 9, MOD-10).
//
// Single white card (capped at 720px tall), flex column:
//   1. Header — 40px orange-tint ✉ tile, group name, green status line with
//      the live member count, overlapping member avatars right.
//   2. Message area — cream (#FBF6F0) scrollable thread with centered day
//      pills; others' bubbles left (white, tinted avatar + name label,
//      radius 16/16/16/4), own bubbles right (orange, cream text, radius
//      16/16/4/16); Space-Mono timestamps under each.
//   3. Composer — cream pill input + 44px round orange send button.
//
// Uses the same chatThreadControllerProvider (optimistic send + silent
// 4s polling) and markRead flow the mobile thread uses — visuals only.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../../profile/application/profile_controllers.dart';
import '../../team/application/team_providers.dart';
import '../application/chat_providers.dart';
import '../domain/chat_group.dart';
import '../domain/chat_message.dart';

/// The wide-web chat card. Pure presentation over the existing providers.
class WebChat extends ConsumerWidget {
  const WebChat({super.key, required this.groupAsync, required this.group});

  final AsyncValue<ChatGroup?> groupAsync;
  final ChatGroup? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.topCenter,
      child: LayoutBuilder(builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(320.0, 720.0)
            : 720.0;
        return SizedBox(
          height: h,
          child: WebEntrance(
            delay: const Duration(milliseconds: 50),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: WebTheme.surface,
                borderRadius: BorderRadius.circular(WebTheme.rCard),
                border: Border.all(color: WebTheme.hairline),
                boxShadow: WebTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _Header(group: group),
                  const Divider(height: 1, color: WebTheme.hairline),
                  Expanded(
                    child: groupAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: WebTheme.orange, strokeWidth: 2.5)),
                      error: (_, _) => _CenterNote(
                        text: 'Could not load the team chat.',
                        actionLabel: 'RETRY',
                        onAction: () => ref.invalidate(myGroupProvider),
                      ),
                      data: (g) {
                        if (g == null) {
                          return _CenterNote(
                            text:
                                'No team channel yet — create one to start '
                                'coordinating with your team.',
                            actionLabel: 'CREATE CHANNEL',
                            onAction: () async {
                              try {
                                await ref
                                    .read(chatRepositoryProvider)
                                    .createGroup();
                                ref.invalidate(myGroupProvider);
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not create the channel.')),
                                );
                              }
                            },
                          );
                        }
                        return _Thread(groupId: g.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends ConsumerWidget {
  const _Header({this.group});
  final ChatGroup? group;

  static const _avatarPalettes = [
    (Color(0xFFFFF3E8), Color(0xFFB8430A)),
    (Color(0xFFF3EEFD), Color(0xFF6D3FD4)),
    (Color(0xFFE9F7F0), Color(0xFF1E9E6A)),
    (Color(0xFFFFF7E5), Color(0xFFB8860B)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider).valueOrNull ?? const [];
    final title = group?.name.trim().isNotEmpty == true
        ? group!.name.trim()
        : 'Team Chat';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WebTheme.orangeTint,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: WebTheme.orangeTintBorder),
            ),
            child: const Center(
                child: Text('✉', style: TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.displayStyle(size: 15)),
                const SizedBox(height: 2),
                Text(
                  '● ${members.length} members · text-only · offline queue on',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTheme.bodyStyle(
                      size: 11, color: WebTheme.success),
                ),
              ],
            ),
          ),
          // Overlapping member avatars.
          for (var i = 0; i < members.take(4).length; i++)
            Align(
              widthFactor: i == 0 ? 1 : 0.7,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _avatarPalettes[i % _avatarPalettes.length].$1,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    members[i].fullName.isEmpty
                        ? '?'
                        : members[i].fullName[0].toUpperCase(),
                    style: WebTheme.bodyStyle(
                      size: 11,
                      weight: FontWeight.w700,
                      color:
                          _avatarPalettes[i % _avatarPalettes.length].$2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── THREAD
class _Thread extends ConsumerStatefulWidget {
  const _Thread({required this.groupId});
  final String groupId;

  @override
  ConsumerState<_Thread> createState() => _ThreadState();
}

class _ThreadState extends ConsumerState<_Thread> {
  final _composerCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      ref.read(chatThreadControllerProvider(widget.groupId).notifier).poll();
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

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) {
      return 'TODAY · ${DateFormat('d MMM').format(day).toUpperCase()}';
    }
    if (day == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('d MMM').format(day).toUpperCase();
  }

  Future<void> _send() async {
    final text = _composerCtl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _composerCtl.clear();
    try {
      await ref
          .read(chatThreadControllerProvider(widget.groupId).notifier)
          .send(text);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(currentUserProvider).value?.id;
    final selfRemoteId = ref.watch(currentUserProvider).value?.remoteId;
    final messages =
        ref.watch(chatThreadControllerProvider(widget.groupId));

    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: WebTheme.pageBg,
            child: messages.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: WebTheme.orange, strokeWidth: 2.5)),
              error: (_, _) => _CenterNote(
                text: 'Could not load messages.',
                actionLabel: 'RETRY',
                onAction: () => ref
                    .read(chatThreadControllerProvider(widget.groupId)
                        .notifier)
                    .refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet — say hello to the team 👋',
                      style: WebTheme.bodyStyle(
                          size: 13, color: WebTheme.inkMuted),
                    ),
                  );
                }
                final rows = <Widget>[];
                DateTime? lastDay;
                for (final m in items) {
                  final local = m.sentAt.toLocal();
                  final day =
                      DateTime(local.year, local.month, local.day);
                  if (lastDay != day) {
                    rows.add(_DayPill(label: _dayLabel(day)));
                    lastDay = day;
                  }
                  final isSelf = m.senderId == '_self' ||
                      (selfId != null && m.senderId == selfId) ||
                      (selfRemoteId != null &&
                          m.senderId == selfRemoteId);
                  rows.add(_Bubble(message: m, isSelf: isSelf));
                }
                return ListView(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  children: rows,
                );
              },
            ),
          ),
        ),
        // Composer — cream pill + round orange send.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: WebTheme.surface,
            border: Border(top: BorderSide(color: WebTheme.hairline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _composerCtl,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !_sending,
                  style: WebTheme.bodyStyle(size: 13),
                  cursorColor: WebTheme.orange,
                  decoration: InputDecoration(
                    hintText: 'Message the team…',
                    hintStyle: WebTheme.bodyStyle(
                        size: 13, color: WebTheme.inkFaint),
                    filled: true,
                    fillColor: WebTheme.pageBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide:
                          const BorderSide(color: WebTheme.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide:
                          const BorderSide(color: WebTheme.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide:
                          const BorderSide(color: WebTheme.orange),
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              WebHoverLift(
                onTap: _sending ? null : _send,
                borderRadius: 999,
                enableShadow: false,
                liftScale: 1.06,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WebTheme.orange,
                    shape: BoxShape.circle,
                    boxShadow: WebTheme.buttonGlow,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── BUBBLE
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isSelf});
  final ChatMessage message;
  final bool isSelf;

  static const _namePalette = [
    Color(0xFFB8430A),
    Color(0xFF6D3FD4),
    Color(0xFF1E9E6A),
    Color(0xFFB8860B),
    Color(0xFFD64545),
  ];

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.sentAt.toLocal());
    final name = message.senderName?.trim().isNotEmpty == true
        ? message.senderName!.trim()
        : 'Member';
    final colorIdx = message.senderId.hashCode.abs() % _namePalette.length;
    final nameColor = _namePalette[colorIdx];

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelf ? WebTheme.orange : WebTheme.surface,
          border:
              isSelf ? null : Border.all(color: WebTheme.innerLine),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSelf ? 16 : 4),
            bottomRight: Radius.circular(isSelf ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: WebTheme.bodyStyle(
            size: 13,
            color: isSelf ? WebTheme.chromeInk : WebTheme.ink,
            height: 1.45,
          ),
        ),
      ),
    );

    if (isSelf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bubble,
            const SizedBox(height: 3),
            Text(time,
                style: WebTheme.label(
                    size: 8.5, color: WebTheme.inkFaint, tracking: 0.05)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: nameColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: WebTheme.bodyStyle(
                    size: 12, weight: FontWeight.w700, color: nameColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: WebTheme.bodyStyle(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: nameColor)),
              const SizedBox(height: 3),
              bubble,
              const SizedBox(height: 3),
              Text(time,
                  style: WebTheme.label(
                      size: 8.5,
                      color: WebTheme.inkFaint,
                      tracking: 0.05)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Centered date pill ("TODAY · 11 JUL").
class _DayPill extends StatelessWidget {
  const _DayPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 2),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: WebTheme.innerLine),
          ),
          child: Text(label,
              style: WebTheme.label(
                  size: 8.5, color: WebTheme.inkMuted, tracking: 0.12)),
        ),
      ),
    );
  }
}

/// Centered note + mono action link (error/empty states).
class _CenterNote extends StatelessWidget {
  const _CenterNote({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style:
                  WebTheme.bodyStyle(size: 13, color: WebTheme.inkMuted),
            ),
          ),
          const SizedBox(height: 12),
          WebHoverHighlight(
            onTap: onAction,
            borderRadius: WebTheme.rFull,
            builder: (context, hovering) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: hovering ? WebTheme.orangeDark : WebTheme.orange,
                borderRadius: BorderRadius.circular(WebTheme.rFull),
              ),
              child: Text(actionLabel,
                  style: WebTheme.label(
                      size: 9,
                      color: WebTheme.chromeInk,
                      tracking: 0.1)),
            ),
          ),
        ],
      ),
    );
  }
}
