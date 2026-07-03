// lib/features/admin/domain/admin_broadcast.dart
//
// Admin-side view of a platform broadcast — the writable counterpart to
// `features/broadcasts/domain/broadcast.dart` (which is read-only, for the
// studio-facing "Platform Updates" feed). Maps 1:1 onto `BroadcastResource`.

class AdminBroadcast {
  const AdminBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.isActive,
    this.targetRole,
    this.priority = 'Normal',
    this.type = 'Announcement',
    this.link,
    this.buttonLabel,
    this.imageUrl,
    this.timesPerDay = 1,
    this.viewCount = 0,
    this.clickCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isActive;
  final String? targetRole;
  final String priority;
  final String type;
  final String? link;
  final String? buttonLabel;
  final String? imageUrl;
  final int timesPerDay;
  final int viewCount;
  final int clickCount;
  final DateTime? createdAt;

  factory AdminBroadcast.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    int n(Object? v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return AdminBroadcast(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['content'] ?? '').toString(),
      isActive: json['is_active'] == true || json['status'] == 'ACTIVE',
      targetRole: s(json['target_role'] ?? json['targetRole']),
      priority: (json['priority'] ?? 'Normal').toString(),
      type: (json['type'] ?? 'Announcement').toString(),
      link: s(json['link']),
      buttonLabel: s(json['buttonLabel'] ?? json['button_label']),
      imageUrl: s(json['imageUrl'] ?? json['image_url']),
      timesPerDay: n(json['timesPerDay'] ?? json['times_per_day']) < 1
          ? 1
          : n(json['timesPerDay'] ?? json['times_per_day']),
      viewCount: n(json['view_count']),
      clickCount: n(json['click_count']),
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '').toString()),
    );
  }
}
