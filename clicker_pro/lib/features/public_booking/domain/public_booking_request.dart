// lib/features/public_booking/domain/public_booking_request.dart
//
// Owner-side mirror of a pending public booking submission. The visitor's
// device persists nothing; this type only lives on the Owner's device (and
// in the backend) until it is approved (→ promoted to a real Event) or
// rejected.
//
// Mirrors `PublicBookingRequestsTable` row-for-row plus the lifecycle status.

import '../../bookings/domain/event_type.dart';
import '../../bookings/domain/shift.dart';
import 'public_booking_request_status.dart';

class PublicBookingRequest {
  const PublicBookingRequest({
    required this.id,
    required this.studioId,
    required this.title,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shift,
    required this.clientName,
    required this.clientPhone,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    this.venue,
    this.brideName,
    this.groomName,
    this.clientEmail,
    this.notes,
  });

  /// Server-issued id. The visitor never has a local copy of this row, so
  /// there is no separate `remoteId` field — `id` IS the remote id.
  final String id;

  final String studioId;
  final String title;
  final EventType eventType;
  final DateTime date;

  /// `HH:mm` 24-hour clock, matching the Drift schema.
  final String startTime;
  final String endTime;

  final Shift shift;
  final String? venue;

  /// Only meaningful when [eventType] is `wedding` or `holud`.
  final String? brideName;
  final String? groomName;

  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final String? notes;

  final PublicBookingRequestStatus status;
  final DateTime submittedAt;
  final DateTime updatedAt;

  PublicBookingRequest copyWith({
    String? id,
    String? studioId,
    String? title,
    EventType? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    Shift? shift,
    String? venue,
    String? brideName,
    String? groomName,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? notes,
    PublicBookingRequestStatus? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return PublicBookingRequest(
      id: id ?? this.id,
      studioId: studioId ?? this.studioId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shift: shift ?? this.shift,
      venue: venue ?? this.venue,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studioId': studioId,
    'title': title,
    'eventType': eventType.name,
    'date': date.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'shift': shift.name,
    if (venue != null) 'venue': venue,
    if (brideName != null) 'brideName': brideName,
    if (groomName != null) 'groomName': groomName,
    'clientName': clientName,
    'clientPhone': clientPhone,
    if (clientEmail != null) 'clientEmail': clientEmail,
    if (notes != null) 'notes': notes,
    'status': status.name,
    'submittedAt': submittedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PublicBookingRequest.fromJson(Map<String, dynamic> json) {
    return PublicBookingRequest(
      id: json['id'] as String,
      studioId: json['studioId'] as String,
      title: json['title'] as String,
      eventType: EventType.fromString(json['eventType'] as String),
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      shift: Shift.fromString(json['shift'] as String),
      venue: json['venue'] as String?,
      brideName: json['brideName'] as String?,
      groomName: json['groomName'] as String?,
      clientName: json['clientName'] as String,
      clientPhone: json['clientPhone'] as String,
      clientEmail: json['clientEmail'] as String?,
      notes: json['notes'] as String?,
      status: PublicBookingRequestStatus.fromString(json['status'] as String?),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PublicBookingRequest) return false;
    return other.id == id &&
        other.studioId == studioId &&
        other.title == title &&
        other.eventType == eventType &&
        other.date == date &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.shift == shift &&
        other.venue == venue &&
        other.brideName == brideName &&
        other.groomName == groomName &&
        other.clientName == clientName &&
        other.clientPhone == clientPhone &&
        other.clientEmail == clientEmail &&
        other.notes == notes &&
        other.status == status &&
        other.submittedAt == submittedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    studioId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    venue,
    brideName,
    groomName,
    clientName,
    clientPhone,
    clientEmail,
    notes,
    status,
    submittedAt,
    updatedAt,
  ]);
}
