// lib/features/chat/domain/chat_message.dart
//
// Single chat message।  Backend response shape:
//   { id, groupId, senderId, text, sentAt, sender: { fullName, role } }

class ChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final String? senderName;
  final String? senderRole;

  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.senderName,
    this.senderRole,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = (json['sender'] as Map?)?.cast<String, dynamic>();
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      sentAt: json['sentAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['sentAt'].toString()),
      senderName: sender?['fullName'] as String?,
      senderRole: sender?['role'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          id == other.id &&
          groupId == other.groupId &&
          senderId == other.senderId &&
          text == other.text &&
          sentAt == other.sentAt);

  @override
  int get hashCode => Object.hash(id, groupId, senderId, text, sentAt);
}
