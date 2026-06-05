// lib/features/bookings/domain/client.dart
//
// Domain entity for a Client (the customer attached to a Booking). Owned
// by the studio that created it; phone is unique per studio so the
// inline-create flow on the booking edit screen can reuse an existing row
// when the same phone reappears.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 2.7, 13.7, 13.8.

/// A studio's customer record. Linked from a [Booking] via `clientId`.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
class Client {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Studio scope. Combined with [phone] forms the unique key.
  final String studioId;

  /// Display name (1..80 chars).
  final String name;

  /// Phone number. Unique per studio — the inline-create flow looks up
  /// the existing row by this field before creating a new one.
  final String phone;

  /// Optional email; surfaced on the booking detail screen.
  final String? email;

  /// Optional postal address; surfaced on the booking detail screen.
  final String? address;

  /// Optional date of birth; powers a future "client reminders" feature.
  final DateTime? dob;

  /// Optional anniversary; powers a future "client reminders" feature.
  final DateTime? anniversary;

  /// Wall-clock timestamp at first creation.
  final DateTime createdAt;

  /// Most recent edit timestamp; reconciled via last-write-wins.
  final DateTime updatedAt;

  /// True while the client has unsynced changes in the outbox.
  final bool pending;

  Client({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.dob,
    this.anniversary,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
  });

  Client copyWith({
    String? id,
    String? remoteId,
    String? studioId,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? dob,
    DateTime? anniversary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return Client(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      anniversary: anniversary ?? this.anniversary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'studioId': studioId,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (dob != null) 'dob': dob!.toIso8601String(),
      if (anniversary != null) 'anniversary': anniversary!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      studioId: json['studioId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      dob: json['dob'] == null ? null : DateTime.parse(json['dob'] as String),
      anniversary: json['anniversary'] == null
          ? null
          : DateTime.parse(json['anniversary'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Client) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        studioId == other.studioId &&
        name == other.name &&
        phone == other.phone &&
        email == other.email &&
        address == other.address &&
        dob == other.dob &&
        anniversary == other.anniversary &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    studioId,
    name,
    phone,
    email,
    address,
    dob,
    anniversary,
    createdAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() => 'Client(id: $id, name: $name, phone: $phone)';
}
