// lib/features/bookings/domain/booking.dart
//
// Domain entity for a Booking (a.k.a. Event). Captures the full editable
// shape of a booking across new/edit, list, detail, calendar, and
// finance-summary screens. The 30-field shape mirrors the design's
// "Data Models" section exactly so JSON round-trip (Property 9) and
// last-write-wins reconciliation (Property 8) can compare instances by
// structural equality.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports. Drift conversions
// happen in `BookingsDao`; API conversions happen in `booking_serializers`.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 2.1, 5.2, 7.2–7.4, 8.1–8.3, 9.1, 13.2.

import '../../../core/booking_status/booking_status.dart';
import 'event_type.dart';
import 'shift.dart';

/// A scheduled photography / videography booking.
///
/// Instances are immutable; use [copyWith] to derive modified copies. JSON
/// serialization round-trips via [toJson] / [fromJson] preserving
/// structural equality (Property 9).
class Booking {
  /// Local UUID, generated client-side. Stable across sync — never
  /// rewritten when the server assigns a [remoteId].
  final String id;

  /// Server-assigned id, populated on first successful sync. `null` while
  /// the booking is still pending in the outbox.
  final String? remoteId;

  /// Studio scope. Owner/Both/Manager booking rows carry the owner's id;
  /// Freelancer rows carry the freelancer's own id.
  final String studioId;

  /// User id of whoever created the booking. Used by the role-scope
  /// predicate to grant Manager/Freelancer visibility on their own rows.
  final String createdByUserId;

  /// Free-form booking title (1..120 chars). Validated by
  /// `BookingEditController` at save time; stored verbatim.
  final String title;

  /// Event category — drives the bride/groom-required form rule.
  final EventType eventType;

  /// Calendar date of the event (date portion authoritative).
  final DateTime date;

  /// `HH:mm` start time. Combined with [date] for sorting / clash detection.
  final String startTime;

  /// `HH:mm` end time. Must satisfy `endTime >= startTime` per Requirement 2.4.
  final String endTime;

  /// Day / night / both — affects payout sheet and assignment UI.
  final Shift shift;

  /// Venue name; free-form when set.
  final String? venue;

  /// True if the shoot is at an outdoor location. Drives an icon on the
  /// list row and a checkbox on the edit form.
  final bool outdoor;

  /// Bride name. Required when [EventType.requiresBrideGroom] is true.
  final String? brideName;

  /// Groom name. Required when [EventType.requiresBrideGroom] is true.
  final String? groomName;

  /// Linked client local id. Nullable until a client is picked or created
  /// via the inline-create flow.
  final String? clientId;

  /// Client display name. MOD-07 v6 required form field, stored directly
  /// on the booking so the form round-trips without a ClientsTable join.
  final String? clientName;

  /// Client contact phone. MOD-07 v6: required for Owner/Both modes.
  final String? clientPhone;

  /// Linked package local id. Mutually exclusive with [customPrice] —
  /// edit form ensures only one is set at a time (Requirement 2.11).
  final String? packageId;

  /// Custom price when no package is linked. Mutually exclusive with
  /// [packageId].
  final double? customPrice;

  /// Default coverage hours used to compute due / extras when no package
  /// override applies.
  final double? coverageHours;

  /// Override hourly rate for time beyond [coverageHours]. Falls back to
  /// the package value when the booking is package-driven.
  final double? extraHourRate;

  /// Optional Google Drive / Docs URL for delivery assets. Validated as a
  /// Drive/Docs URL pattern at save time.
  final String? driveLink;

  /// Free-form JSON map for client-supplied requirements (e.g. shot list,
  /// color preferences). Stored verbatim and round-tripped through JSON.
  final Map<String, dynamic>? clientRequirements;

  /// Internal notes visible to staff but not the client.
  final String? notes;

  /// Local user id of the booking's chief photographer, when designated.
  final String? chiefPhotographerUserId;

  /// Coverage hours billed to the chief photographer specifically. Used
  /// for payout splits when the chief commands a different rate.
  final double? chiefHours;

  /// When `true`, payment-related fields are hidden from Manager users
  /// per Requirement 5.3 (Owner / Both / Freelancer always see them).
  final bool hidePaymentFromTeam;

  /// Owner opt-in: when `true`, payment figures (total/advance/due) are
  /// included on the *shared event details* sent to the team and
  /// freelancers. Default `false` — shared details never expose money
  /// unless the owner explicitly turns this on. (The client invoice always
  /// shows payment regardless of this flag.)
  final bool showPaymentInShare;

  /// Lifecycle status. Transitions through [BookingStatusMachine]; cannot
  /// be set arbitrarily — `StatusRepository.transition` is the only legal
  /// mutation path.
  final BookingStatus status;

  /// Wall-clock timestamp at first creation. Set client-side, never
  /// overwritten by sync.
  final DateTime createdAt;

  /// Most recent edit timestamp. Bumped on every local write and
  /// reconciled via last-write-wins (Tier A).
  final DateTime updatedAt;

  /// True while the booking has unsynced changes in the outbox; flips to
  /// `false` once the worker drains successfully.
  final bool pending;

  Booking({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.createdByUserId,
    required this.title,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shift,
    this.venue,
    this.outdoor = false,
    this.brideName,
    this.groomName,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.packageId,
    this.customPrice,
    this.coverageHours,
    this.extraHourRate,
    this.driveLink,
    this.clientRequirements,
    this.notes,
    this.chiefPhotographerUserId,
    this.chiefHours,
    this.hidePaymentFromTeam = false,
    this.showPaymentInShare = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
  });

  /// Returns a copy with the supplied fields replaced. Passing `null`
  /// for any nullable field leaves the existing value unchanged — to
  /// explicitly null-out a nullable field, construct a fresh instance.
  Booking copyWith({
    String? id,
    String? remoteId,
    String? studioId,
    String? createdByUserId,
    String? title,
    EventType? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    Shift? shift,
    String? venue,
    bool? outdoor,
    String? brideName,
    String? groomName,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? packageId,
    double? customPrice,
    double? coverageHours,
    double? extraHourRate,
    String? driveLink,
    Map<String, dynamic>? clientRequirements,
    String? notes,
    String? chiefPhotographerUserId,
    double? chiefHours,
    bool? hidePaymentFromTeam,
    bool? showPaymentInShare,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return Booking(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shift: shift ?? this.shift,
      venue: venue ?? this.venue,
      outdoor: outdoor ?? this.outdoor,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      packageId: packageId ?? this.packageId,
      customPrice: customPrice ?? this.customPrice,
      coverageHours: coverageHours ?? this.coverageHours,
      extraHourRate: extraHourRate ?? this.extraHourRate,
      driveLink: driveLink ?? this.driveLink,
      clientRequirements: clientRequirements ?? this.clientRequirements,
      notes: notes ?? this.notes,
      chiefPhotographerUserId:
          chiefPhotographerUserId ?? this.chiefPhotographerUserId,
      chiefHours: chiefHours ?? this.chiefHours,
      hidePaymentFromTeam: hidePaymentFromTeam ?? this.hidePaymentFromTeam,
      showPaymentInShare: showPaymentInShare ?? this.showPaymentInShare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  /// Serializes this booking to its wire JSON shape.
  ///
  /// Optional fields are omitted when null so the round-trip is
  /// symmetric — `fromJson(toJson(b)) == b` even when most nullable
  /// fields are unset.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'studioId': studioId,
      'createdByUserId': createdByUserId,
      'title': title,
      'eventType': eventType.name,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'shift': shift.name,
      if (venue != null) 'venue': venue,
      'outdoor': outdoor,
      if (brideName != null) 'brideName': brideName,
      if (groomName != null) 'groomName': groomName,
      if (clientId != null) 'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      if (clientPhone != null) 'clientPhone': clientPhone,
      if (packageId != null) 'packageId': packageId,
      if (customPrice != null) 'customPrice': customPrice,
      if (coverageHours != null) 'coverageHours': coverageHours,
      if (extraHourRate != null) 'extraHourRate': extraHourRate,
      if (driveLink != null) 'driveLink': driveLink,
      if (clientRequirements != null) 'clientRequirements': clientRequirements,
      if (notes != null) 'notes': notes,
      if (chiefPhotographerUserId != null)
        'chiefPhotographerUserId': chiefPhotographerUserId,
      if (chiefHours != null) 'chiefHours': chiefHours,
      'hidePaymentFromTeam': hidePaymentFromTeam,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  /// Parses a wire JSON map back into a [Booking]. Unknown enum strings
  /// fall back to safe defaults so a single bad row doesn't crash the
  /// list view; corrupt rows are surfaced through telemetry instead.
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      studioId: json['studioId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      title: json['title'] as String,
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['eventType'] as String,
        orElse: () => EventType.other,
      ),
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      shift: Shift.values.firstWhere(
        (s) => s.name == json['shift'] as String,
        orElse: () => Shift.day,
      ),
      venue: json['venue'] as String?,
      outdoor: json['outdoor'] as bool? ?? false,
      brideName: json['brideName'] as String?,
      groomName: json['groomName'] as String?,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      packageId: json['packageId'] as String?,
      customPrice: (json['customPrice'] as num?)?.toDouble(),
      coverageHours: (json['coverageHours'] as num?)?.toDouble(),
      extraHourRate: (json['extraHourRate'] as num?)?.toDouble(),
      driveLink: json['driveLink'] as String?,
      clientRequirements: json['clientRequirements'] == null
          ? null
          : Map<String, dynamic>.from(json['clientRequirements'] as Map),
      notes: json['notes'] as String?,
      chiefPhotographerUserId: json['chiefPhotographerUserId'] as String?,
      chiefHours: (json['chiefHours'] as num?)?.toDouble(),
      hidePaymentFromTeam: json['hidePaymentFromTeam'] as bool? ?? false,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Booking) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        studioId == other.studioId &&
        createdByUserId == other.createdByUserId &&
        title == other.title &&
        eventType == other.eventType &&
        date == other.date &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        shift == other.shift &&
        venue == other.venue &&
        outdoor == other.outdoor &&
        brideName == other.brideName &&
        groomName == other.groomName &&
        clientId == other.clientId &&
        clientName == other.clientName &&
        clientPhone == other.clientPhone &&
        packageId == other.packageId &&
        customPrice == other.customPrice &&
        coverageHours == other.coverageHours &&
        extraHourRate == other.extraHourRate &&
        driveLink == other.driveLink &&
        _jsonEquals(clientRequirements, other.clientRequirements) &&
        notes == other.notes &&
        chiefPhotographerUserId == other.chiefPhotographerUserId &&
        chiefHours == other.chiefHours &&
        hidePaymentFromTeam == other.hidePaymentFromTeam &&
        status == other.status &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    studioId,
    createdByUserId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    venue,
    outdoor,
    brideName,
    groomName,
    clientId,
    clientName,
    clientPhone,
    packageId,
    customPrice,
    coverageHours,
    extraHourRate,
    driveLink,
    _jsonHash(clientRequirements),
    notes,
    chiefPhotographerUserId,
    chiefHours,
    hidePaymentFromTeam,
    status,
    createdAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'Booking(id: $id, title: $title, date: $date, status: ${status.name}, '
      'pending: $pending)';
}

/// Recursive JSON-shape equality. Compares [Map]s and [List]s element-wise
/// and falls back to `==` for primitives. Used by [Booking] to compare
/// the freeform [Booking.clientRequirements] map structurally.
bool _jsonEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_jsonEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Order-sensitive list / order-independent map hash that matches the
/// recursion in [_jsonEquals]. Returns `0` for `null` so hash collisions
/// only happen when contents truly match.
int _jsonHash(Object? value) {
  if (value == null) return 0;
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map((e) => Object.hash(e.key, _jsonHash(e.value))),
    );
  }
  if (value is List) {
    return Object.hashAll(value.map(_jsonHash));
  }
  return value.hashCode;
}
