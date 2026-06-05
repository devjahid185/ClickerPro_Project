// lib/features/notifications/domain/app_notification.dart
//
// In-app notification record returned by `GET /api/notifications`।
//
// Backend model (Prisma `Notification`):
//   { id, userId, category, message, read, sentAt, deeplink? }
//
// Categories the backend currently emits:
//   • OPERATIONS   — new public booking request, status changes
//   • PAYMENT      — payment recorded
//   • REEDIT       — re-edit assigned / progress
//   • ANNOUNCEMENT — broadcast from owner
//   • WISH         — birthday / anniversary auto-greetings
//
// We keep `category` as a free-form string so the backend can introduce
// new categories without a Flutter release; the UI maps a small set to
// dedicated icons and falls back to a neutral icon for unknown values।

class AppNotification {
  final String id;
  final String category;
  final String message;
  final bool read;
  final DateTime sentAt;
  final String? deeplink;

  const AppNotification({
    required this.id,
    required this.category,
    required this.message,
    required this.read,
    required this.sentAt,
    this.deeplink,
  });

  AppNotification copyWith({
    String? id,
    String? category,
    String? message,
    bool? read,
    DateTime? sentAt,
    String? deeplink,
  }) {
    return AppNotification(
      id: id ?? this.id,
      category: category ?? this.category,
      message: message ?? this.message,
      read: read ?? this.read,
      sentAt: sentAt ?? this.sentAt,
      deeplink: deeplink ?? this.deeplink,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? 'OTHER').toString(),
      message: (json['message'] ?? '').toString(),
      read: json['read'] as bool? ?? false,
      sentAt: json['sentAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['sentAt'] as String),
      deeplink: json['deeplink'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppNotification) return false;
    return id == other.id &&
        category == other.category &&
        message == other.message &&
        read == other.read &&
        sentAt == other.sentAt &&
        deeplink == other.deeplink;
  }

  @override
  int get hashCode =>
      Object.hash(id, category, message, read, sentAt, deeplink);

  @override
  String toString() =>
      'AppNotification(id: $id, category: $category, read: $read)';
}
