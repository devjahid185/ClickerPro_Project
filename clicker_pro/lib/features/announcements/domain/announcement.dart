class Announcement {
  final String id;
  final String ownerId;
  final String title;
  final String body;
  final bool pinned;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final List<String> readBy;

  const Announcement({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.body,
    this.pinned = false,
    this.expiresAt,
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isRead => readBy.isNotEmpty;

  int get readCount => readBy.length;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'body': body,
    'pinned': pinned,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'body': body,
    'pinned': pinned,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'readBy': readBy,
  };

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      pinned: json['pinned'] as bool? ?? false,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'].toString()),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'].toString()),
      readBy:
          (json['readBy'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  Announcement copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? body,
    bool? pinned,
    DateTime? expiresAt,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return Announcement(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      body: body ?? this.body,
      pinned: pinned ?? this.pinned,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Announcement &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          pinned == other.pinned &&
          expiresAt == other.expiresAt &&
          createdAt == other.createdAt);

  @override
  int get hashCode =>
      Object.hash(id, title, body, pinned, expiresAt, createdAt);
}
