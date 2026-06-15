/// A platform-wide announcement pushed by an admin (distinct from the
/// owner-scoped [Announcement]). Read-only on the app side — created and
/// managed from the web admin panel. Tapping one opens [link] if present.
class Broadcast {
  final String id;
  final String title;
  final String content;
  final String priority; // Normal | Important | Emergency
  final String type; // Announcement | Update | Maintenance
  final String? imageUrl;
  final String? link;
  final String? buttonLabel;

  /// How many times per day this broadcast may pop up for a user. Set by the
  /// admin per broadcast; defaults to 1. The app tracks per-day counts.
  final int timesPerDay;
  final DateTime createdAt;

  const Broadcast({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.type,
    this.imageUrl,
    this.link,
    this.buttonLabel,
    this.timesPerDay = 1,
    required this.createdAt,
  });

  bool get hasLink => link != null && link!.trim().isNotEmpty;

  bool get isEmergency => priority.toLowerCase() == 'emergency';
  bool get isImportant => priority.toLowerCase() == 'important';

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    return Broadcast(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      priority: (json['priority'] ?? 'Normal').toString(),
      type: (json['type'] ?? 'Announcement').toString(),
      imageUrl: s(json['imageUrl']),
      link: s(json['link']),
      buttonLabel: s(json['buttonLabel']),
      timesPerDay: () {
        final v = json['timesPerDay'] ?? json['times_per_day'];
        final n = (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');
        return (n == null || n < 1) ? 1 : n;
      }(),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    );
  }
}
