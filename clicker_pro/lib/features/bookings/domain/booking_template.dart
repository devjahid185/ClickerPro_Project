import '../../bookings/domain/event_type.dart';
import '../../bookings/domain/shift.dart';

class BookingTemplate {
  final String id;
  final String name;
  final EventType eventType;
  final Shift shift;
  final String? venue;
  final String? packageId;
  final String? notes;

  const BookingTemplate({
    required this.id,
    required this.name,
    required this.eventType,
    required this.shift,
    this.venue,
    this.packageId,
    this.notes,
  });

  BookingTemplate copyWith({
    String? id,
    String? name,
    EventType? eventType,
    Shift? shift,
    String? venue,
    String? packageId,
    String? notes,
  }) {
    return BookingTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      eventType: eventType ?? this.eventType,
      shift: shift ?? this.shift,
      venue: venue ?? this.venue,
      packageId: packageId ?? this.packageId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'eventType': eventType.name,
      'shift': shift.name,
      if (venue != null) 'venue': venue,
      if (packageId != null) 'packageId': packageId,
      if (notes != null) 'notes': notes,
    };
  }

  factory BookingTemplate.fromJson(Map<String, dynamic> json) {
    return BookingTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['eventType'] as String,
        orElse: () => EventType.other,
      ),
      shift: Shift.values.firstWhere(
        (s) => s.name == json['shift'] as String,
        orElse: () => Shift.day,
      ),
      venue: json['venue'] as String?,
      packageId: json['packageId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookingTemplate) return false;
    return id == other.id &&
        name == other.name &&
        eventType == other.eventType &&
        shift == other.shift &&
        venue == other.venue &&
        packageId == other.packageId &&
        notes == other.notes;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, eventType, shift, venue, packageId, notes);
}
