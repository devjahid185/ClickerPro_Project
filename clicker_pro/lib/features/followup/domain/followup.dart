enum FollowupType { album, payment, feedback }

class Followup {
  final String id;
  final String bookingId;
  final FollowupType type;
  final DateTime scheduledDate;
  final bool completed;

  const Followup({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.scheduledDate,
    this.completed = false,
  });

  Followup copyWith({
    String? id,
    String? bookingId,
    FollowupType? type,
    DateTime? scheduledDate,
    bool? completed,
  }) {
    return Followup(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'bookingId': bookingId,
      'type': type.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completed': completed,
    };
  }

  /// Payload for `POST /api/followups`.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      if (bookingId.isNotEmpty) 'event_id': bookingId,
      'type': type.name,
      'scheduled_date': scheduledDate.toIso8601String().split('T').first,
    };
  }

  factory Followup.fromJson(Map<String, dynamic> json) {
    // Tolerates both local (camelCase, String id) and Laravel
    // (snake_case, int id/event_id) shapes.
    return Followup(
      id: json['id'].toString(),
      bookingId: (json['bookingId'] ?? json['event_id'] ?? '').toString(),
      type: FollowupType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'feedback'),
        orElse: () => FollowupType.feedback,
      ),
      scheduledDate: DateTime.parse(
        (json['scheduledDate'] ?? json['scheduled_date']) as String,
      ),
      completed: json['completed'] == true || json['completed'] == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Followup) return false;
    return id == other.id &&
        bookingId == other.bookingId &&
        type == other.type &&
        scheduledDate == other.scheduledDate &&
        completed == other.completed;
  }

  @override
  int get hashCode =>
      Object.hash(id, bookingId, type, scheduledDate, completed);
}
