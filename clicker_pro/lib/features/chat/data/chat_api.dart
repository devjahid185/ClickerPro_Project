// lib/features/chat/data/chat_api.dart
//
// Laravel contract (routes/api.php + ChatController):
//   GET  /api/chat/groups                    -> { data: [group...] }
//        (server auto-creates the default "Team Chat" on first call)
//   POST /api/chat/groups {name}             -> { data: group }
//   GET  /api/chat/groups/{id}/messages      -> { data: [message...] }
//   POST /api/chat/groups/{id}/messages {body} -> { data: message }

import '../../../core/network/api_client.dart';
import '../domain/chat_group.dart';
import '../domain/chat_message.dart';

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  /// The team's chat group. The backend auto-creates "Team Chat" when
  /// none exists, so this only returns null on a malformed response.
  Future<ChatGroup?> myGroup() async {
    final r = await _client.get('/api/chat/groups') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    if (raw.isEmpty) return null;
    return ChatGroup.fromJson((raw.first as Map).cast<String, dynamic>());
  }

  Future<ChatGroup> createGroup() async {
    final r =
        await _client.post('/api/chat/groups', body: {'name': 'Team Chat'})
            as Map<String, dynamic>;
    return ChatGroup.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  Future<List<ChatMessage>> messages(String groupId) async {
    final r =
        await _client.get('/api/chat/groups/$groupId/messages')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<ChatMessage> send({
    required String groupId,
    required String text,
  }) async {
    final r =
        await _client.post(
              '/api/chat/groups/$groupId/messages',
              body: {'body': text},
            )
            as Map<String, dynamic>;
    return ChatMessage.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  /// Marks the group's messages as read by the current user (read receipts).
  Future<void> markRead(String groupId) async {
    await _client.post('/api/chat/groups/$groupId/read');
  }
}
