// lib/features/chat/domain/chat_repository.dart

import 'chat_group.dart';
import 'chat_message.dart';

abstract class ChatRepository {
  /// `GET /api/chat/my-group` — returns the studio's group, or null if
  /// none has been created yet (backend 404 → null on Flutter side)।
  Future<ChatGroup?> myGroup();

  /// `POST /api/chat/create-group` — auto-names "Owner's Team Chat"
  /// based on `req.user.fullName` server-side।
  Future<ChatGroup> createGroup();

  /// `GET /api/chat/messages/:groupId` — chronological (oldest first)।
  Future<List<ChatMessage>> messages(String groupId);

  /// `POST /api/chat/send` — `senderId` is taken from JWT, so we only
  /// pass `groupId` and `text`।
  Future<ChatMessage> send({required String groupId, required String text});

  /// Marks the group's messages as seen by the current user (read receipts)।
  Future<void> markRead(String groupId);
}
