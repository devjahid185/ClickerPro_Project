// lib/features/chat/domain/chat_group.dart
//
// Team chat group — one per Owner studio।  Backend response shape
// (controllers/chatController.js):
//   { id, name, ownerId, createdAt }

class ChatGroup {
  final String id;
  final String name;
  final String ownerId;
  final DateTime? createdAt;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    this.createdAt,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    ownerId: (json['ownerId'] ?? '').toString(),
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.tryParse(json['createdAt'].toString()),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatGroup &&
          id == other.id &&
          name == other.name &&
          ownerId == other.ownerId &&
          createdAt == other.createdAt);

  @override
  int get hashCode => Object.hash(id, name, ownerId, createdAt);
}
