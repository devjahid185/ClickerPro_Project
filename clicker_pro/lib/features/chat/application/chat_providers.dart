// lib/features/chat/application/chat_providers.dart
//
// Riverpod wiring for chat:
//
//   1. API + Repo providers — thin construction over `apiClientProvider`
//   2. `myGroupProvider`     — `FutureProvider<ChatGroup?>`, null on 404
//   3. `ChatThreadController` — family-keyed `AsyncNotifier` per group।
//      Holds the message list with optimistic `send()` that prepends a
//      provisional row and reconciles when the server echoes back।

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/chat_api.dart';
import '../data/chat_repository_impl.dart';
import '../domain/chat_group.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.read(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(api: ref.read(chatApiProvider)),
);

/// Owner's group — null if not created yet (backend 404)।
final myGroupProvider = FutureProvider<ChatGroup?>(
  (ref) => ref.read(chatRepositoryProvider).myGroup(),
);

class ChatThreadController
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String groupId) {
    return ref.read(chatRepositoryProvider).messages(groupId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).messages(arg),
    );
  }

  /// Silent live-refresh for polling: fetches the latest messages WITHOUT
  /// flipping to a loading state, so the thread updates in place with no
  /// flicker. Skips the update while a message is mid-send (an unreconciled
  /// `_local-` provisional row is present) so the optimistic row isn't wiped.
  Future<void> poll() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.any((m) => m.id.startsWith('_local-'))) return;
    try {
      final fresh = await ref.read(chatRepositoryProvider).messages(arg);
      state = AsyncData(fresh);
    } catch (_) {
      // Transient poll failure — keep the existing messages on screen.
    }
  }

  /// Sends a message, optimistic-append while the request is in flight।
  /// On success the provisional row is replaced with the server-stamped
  /// one (which carries the real id + sentAt)।  On failure the
  /// provisional row is removed and the error rethrown so the UI can
  /// surface a SnackBar।
  Future<ChatMessage> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'cannot be empty');
    }
    final current = state.valueOrNull ?? const <ChatMessage>[];
    final provisionalId = '_local-${DateTime.now().microsecondsSinceEpoch}';
    final provisional = ChatMessage(
      id: provisionalId,
      groupId: arg,
      senderId: '_self', // overwritten by server response
      text: trimmed,
      sentAt: DateTime.now(),
    );
    state = AsyncData([...current, provisional]);

    try {
      final saved = await ref
          .read(chatRepositoryProvider)
          .send(groupId: arg, text: trimmed);
      // Replace provisional with server-stamped message
      state.whenData((latest) {
        final next = latest
            .where((m) => m.id != provisionalId)
            .toList(growable: false);
        state = AsyncData([...next, saved]);
      });
      return saved;
    } catch (_) {
      // Rollback: drop the provisional row
      state.whenData((latest) {
        state = AsyncData(
          latest.where((m) => m.id != provisionalId).toList(growable: false),
        );
      });
      rethrow;
    }
  }
}

final chatThreadControllerProvider =
    AsyncNotifierProvider.family<
      ChatThreadController,
      List<ChatMessage>,
      String
    >(ChatThreadController.new);
