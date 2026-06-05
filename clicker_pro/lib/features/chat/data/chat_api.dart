// lib/features/chat/data/chat_api.dart

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_group.dart';
import '../domain/chat_message.dart';

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  /// Tolerates a 404 response — backend returns 404 when the user
  /// hasn't created a group yet, which we surface as `null`।
  Future<ChatGroup?> myGroup() async {
    try {
      final r = await _client.get('/api/chat/my-group') as Map<String, dynamic>;
      final data = (r['data'] as Map?)?.cast<String, dynamic>();
      if (data == null) return null;
      return ChatGroup.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ChatGroup> createGroup() async {
    final r =
        await _client.post('/api/chat/create-group') as Map<String, dynamic>;
    return ChatGroup.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  Future<List<ChatMessage>> messages(String groupId) async {
    final r =
        await _client.get('/api/chat/messages/$groupId')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(growable: false);
  }

  Future<ChatMessage> send({
    required String groupId,
    required String text,
  }) async {
    final r =
        await _client.post(
              '/api/chat/send',
              body: {'groupId': groupId, 'text': text},
            )
            as Map<String, dynamic>;
    return ChatMessage.fromJson((r['data'] as Map).cast<String, dynamic>());
  }
}
