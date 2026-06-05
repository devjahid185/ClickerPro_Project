// lib/features/freelancer/domain/fl_blackout_date.dart
//
// Domain entity for a Freelancer Blackout Date (FL-05).
// Freelancers mark dates they are unavailable; owners can view but
// not override. Supports single-date and recurring patterns.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

/// Frequency of a recurring blackout pattern.
enum RecurrencePattern {
  none,
  weekly,
  biweekly,
  monthly,
  yearly;

  static RecurrencePattern fromString(String value) {
    for (final p in RecurrencePattern.values) {
      if (p.name == value) return p;
    }
    return RecurrencePattern.none;
  }
}

/// A date (or recurring range) the freelancer has marked as unavailable.
class FlBlackoutDate {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// The freelancer's user id who owns this blackout entry.
  final String freelancerId;

  /// The primary date of the blackout. For recurring patterns this is the
  /// anchor date from which recurrences are computed.
  final DateTime date;

  /// Optional end date for multi-day blackouts. When null the blackout
  /// applies to [date] only.
  final DateTime? endDate;

  /// Free-form reason (e.g. "Personal trip", "Medical appointment").
  final String? reason;

  /// How often this blackout repeats. [RecurrencePattern.none] means
  /// a one-time blackout.
  final RecurrencePattern recurrence;

  /// Wall-clock timestamp at creation.
  final DateTime createdAt;

  /// Most recent edit timestamp.
  final DateTime updatedAt;

  const FlBlackoutDate({
    required this.id,
    this.remoteId,
    required this.freelancerId,
    required this.date,
    this.endDate,
    this.reason,
    this.recurrence = RecurrencePattern.none,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True when the blackout spans more than a single calendar day.
  bool get isMultiDay => endDate != null && endDate!.isAfter(date);

  /// True when this entry repeats on a schedule.
  bool get isRecurring => recurrence != RecurrencePattern.none;

  FlBlackoutDate copyWith({
    String? id,
    String? remoteId,
    String? freelancerId,
    DateTime? date,
    DateTime? endDate,
    String? reason,
    RecurrencePattern? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlBlackoutDate(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      freelancerId: freelancerId ?? this.freelancerId,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'freelancerId': freelancerId,
      'date': date.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (reason != null) 'reason': reason,
      'recurrence': recurrence.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlBlackoutDate.fromJson(Map<String, dynamic> json) {
    return FlBlackoutDate(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      freelancerId: json['freelancerId'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String?,
      recurrence: RecurrencePattern.fromString(
        (json['recurrence'] as String?) ?? 'none',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlBlackoutDate) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        freelancerId == other.freelancerId &&
        date == other.date &&
        endDate == other.endDate &&
        reason == other.reason &&
        recurrence == other.recurrence &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    freelancerId,
    date,
    endDate,
    reason,
    recurrence,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'FlBlackoutDate(id: $id, date: $date, recurrence: ${recurrence.name})';
}
