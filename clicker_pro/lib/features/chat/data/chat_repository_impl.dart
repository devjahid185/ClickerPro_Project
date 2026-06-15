// lib/features/chat/data/chat_repository_impl.dart

import '../domain/chat_group.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import 'chat_api.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatApi api}) : _api = api;

  final ChatApi _api;

  @override
  Future<ChatGroup?> myGroup() => _api.myGroup();

  @override
  Future<ChatGroup> createGroup() => _api.createGroup();

  @override
  Future<List<ChatMessage>> messages(String groupId) => _api.messages(groupId);

  @override
  Future<ChatMessage> send({required String groupId, required String text}) =>
      _api.send(groupId: groupId, text: text);

  @override
  Future<void> markRead(String groupId) => _api.markRead(groupId);
}
