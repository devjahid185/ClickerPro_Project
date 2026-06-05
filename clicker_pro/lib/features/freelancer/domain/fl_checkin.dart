// lib/features/freelancer/domain/fl_checkin.dart
//
// Domain entity for a Freelancer Live Check-In (FL-09).
// Freelancers tap "I'm Here" on event day; owner sees real-time
// status. Late arrivals trigger a notification alert.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

/// Status of a check-in record.
enum CheckinStatus {
  checkedIn,
  late,
  missed;

  static CheckinStatus fromString(String value) {
    for (final s in CheckinStatus.values) {
      if (s.name == value) return s;
    }
    return CheckinStatus.checkedIn;
  }
}

/// A single check-in record tied to a booking/event.
class FlCheckin {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// The freelancer who checked in.
  final String freelancerId;

  /// The booking/event this check-in is for.
  final String eventId;

  /// Wall-clock time the freelancer tapped "I'm Here".
  final DateTime checkinTime;

  /// The expected start time of the event (copied from booking for
  /// late-detection comparison).
  final DateTime expectedTime;

  /// Whether the check-in was on time or late.
  final CheckinStatus status;

  /// Optional location data (latitude, longitude) for verification.
  final double? latitude;
  final double? longitude;

  /// Wall-clock timestamp at creation.
  final DateTime createdAt;

  const FlCheckin({
    required this.id,
    this.remoteId,
    required this.freelancerId,
    required this.eventId,
    required this.checkinTime,
    required this.expectedTime,
    this.status = CheckinStatus.checkedIn,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// Duration between expected time and actual check-in. Positive means
  /// late; negative means early.
  Duration get lateness => checkinTime.difference(expectedTime);

  bool get isLate => status == CheckinStatus.late;

  FlCheckin copyWith({
    String? id,
    String? remoteId,
    String? freelancerId,
    String? eventId,
    DateTime? checkinTime,
    DateTime? expectedTime,
    CheckinStatus? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return FlCheckin(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      freelancerId: freelancerId ?? this.freelancerId,
      eventId: eventId ?? this.eventId,
      checkinTime: checkinTime ?? this.checkinTime,
      expectedTime: expectedTime ?? this.expectedTime,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'freelancerId': freelancerId,
      'eventId': eventId,
      'checkinTime': checkinTime.toIso8601String(),
      'expectedTime': expectedTime.toIso8601String(),
      'status': status.name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlCheckin.fromJson(Map<String, dynamic> json) {
    return FlCheckin(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      freelancerId: json['freelancerId'] as String,
      eventId: json['eventId'] as String,
      checkinTime: DateTime.parse(json['checkinTime'] as String),
      expectedTime: DateTime.parse(json['expectedTime'] as String),
      status: CheckinStatus.fromString(
        (json['status'] as String?) ?? 'checkedIn',
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlCheckin) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        freelancerId == other.freelancerId &&
        eventId == other.eventId &&
        checkinTime == other.checkinTime &&
        expectedTime == other.expectedTime &&
        status == other.status &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    freelancerId,
    eventId,
    checkinTime,
    expectedTime,
    status,
    latitude,
    longitude,
    createdAt,
  ]);

  @override
  String toString() =>
      'FlCheckin(id: $id, eventId: $eventId, status: ${status.name}, '
      'checkinTime: $checkinTime)';
}
