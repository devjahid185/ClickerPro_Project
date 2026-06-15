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

  /// User ids (as strings) that have seen this message — drives the read
  /// receipt on the sender's own bubbles.
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.senderName,
    this.senderRole,
    this.readBy = const <String>[],
  });

  /// How many OTHER members have seen this message.
  int get seenCount => readBy.length;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = (json['sender'] as Map?)?.cast<String, dynamic>();
    final sentRaw = json['sentAt'] ?? json['created_at'] ?? json['createdAt'];
    final readRaw = (json['read_by'] ?? json['readBy']) as List?;
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      groupId: (json['groupId'] ?? json['group_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      // Laravel column is `body`; legacy backend used `text`.
      text: (json['text'] ?? json['body'] ?? '').toString(),
      sentAt: sentRaw == null
          ? DateTime.now()
          : (DateTime.tryParse(sentRaw.toString()) ?? DateTime.now()),
      senderName:
          (sender?['fullName'] ?? sender?['name']) as String?,
      senderRole: sender?['role'] as String?,
      readBy:
          readRaw?.map((e) => e.toString()).toList(growable: false) ??
          const <String>[],
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
