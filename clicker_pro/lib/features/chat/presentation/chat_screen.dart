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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../profile/application/profile_controllers.dart';
import '../../settings/application/language_controller.dart';
import '../application/chat_providers.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final groupAsync = ref.watch(myGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          loc.chat_title,
          style: const TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
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

  @override
  void dispose() {
    _composerCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
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
    final lang = ref.watch(activeLocaleProvider).languageCode == 'bn'
        ? 'bn'
        : 'en';
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
                      style: const TextStyle(
                        color: AppColors.filmDim,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollCtl,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final m = items[i];
                  final isSelf =
                      m.senderId == '_self' ||
                      (selfId != null && m.senderId == selfId) ||
                      (selfRemoteId != null && m.senderId == selfRemoteId);
                  return MessageBubble(message: m, isSelf: isSelf, lang: lang);
                },
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
          decoration: const BoxDecoration(
            color: AppColors.voidLight,
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
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
                    style: const TextStyle(color: AppColors.film),
                    decoration: InputDecoration(
                      hintText: loc.chat_message_hint,
                      hintStyle: const TextStyle(color: AppColors.filmMuted),
                      filled: true,
                      fillColor: AppColors.voidElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.orange),
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
                    minimumSize: const Size(48, 44),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: _sending
                      ? const LensLoader(size: 16)
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
