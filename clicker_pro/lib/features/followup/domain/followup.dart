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

  factory Followup.fromJson(Map<String, dynamic> json) {
    return Followup(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      type: FollowupType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => FollowupType.feedback,
      ),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completed: json['completed'] as bool? ?? false,
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
