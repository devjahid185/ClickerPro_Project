// lib/features/bookings/data/server_wire.dart
//
// Laravel ⇄ Flutter wire adapters for the bookings module.
//
// The Laravel backend wraps every payload in `{ "data": ... }`, uses
// snake_case column names (the raw `events` / `clients` table attributes),
// integer ids, and SCREAMING_SNAKE enum values ('PENDING', 'DAY', …).
// The Flutter domain models were originally written against the old Node
// backend contract (flat camelCase JSON, string ids, camelCase enums).
//
// Everything that translates between those two shapes lives HERE, in one
// place, so the Api classes stay thin and the domain models stay untouched.
//
// Key rules:
//   • Server ids are coerced to String and stored as `remoteId`.
//   • When a [fallback] (the local copy) is provided, the local `id` and
//     every local-only field the server does not persist (startTime,
//     endTime, bride/groom, coverageHours, …) are preserved from it.
//   • Enum values are matched case/underscore-insensitively, falling back
//     to safe defaults so one bad row never crashes a list.

import '../../../core/booking_status/booking_status.dart';
import '../domain/booking.dart';
import '../domain/client.dart';
import '../domain/event_type.dart';
import '../domain/shift.dart';
import '../domain/status_history_entry.dart';

// ───────────────────────── envelope unwrap ─────────────────────────

/// Unwraps `{ "data": {...} }` → the inner map. Tolerates responses that
/// are already flat (returns them unchanged).
Map<String, dynamic> unwrapServerMap(dynamic r) {
  if (r is Map) {
    final data = r['data'];
    if (data is Map) return data.cast<String, dynamic>();
    return r.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

/// Unwraps `{ "data": [...] }` → list of maps. Tolerates `items` (old
/// contract) and bare-list responses.
List<Map<String, dynamic>> unwrapServerList(dynamic r) {
  final Object? raw;
  if (r is Map) {
    raw = r['data'] ?? r['items'] ?? const [];
  } else {
    raw = r;
  }
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList(growable: false);
}

// ───────────────────────── scalar helpers ─────────────────────────

String? serverString(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v != null) {
      final s = v.toString();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

/// Postgres decimals arrive as JSON strings ("5000.00"); ints/doubles as
/// numbers. Coerce both.
double? serverDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? serverDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

String _normalizeEnum(String s) =>
    s.toLowerCase().replaceAll('_', '').replaceAll('-', '');

// ───────────────────────── enum mapping ─────────────────────────

BookingStatus bookingStatusFromServer(
  Object? raw, {
  BookingStatus fallback = BookingStatus.pending,
}) {
  if (raw == null) return fallback;
  final n = _normalizeEnum(raw.toString());
  for (final s in BookingStatus.values) {
    if (_normalizeEnum(s.name) == n) return s;
  }
  return fallback;
}

String bookingStatusToServer(BookingStatus s) {
  switch (s) {
    case BookingStatus.pending:
      return 'PENDING';
    case BookingStatus.confirmed:
      return 'CONFIRMED';
    case BookingStatus.inProgress:
      return 'IN_PROGRESS';
    case BookingStatus.shotComplete:
      return 'SHOT_COMPLETE';
    case BookingStatus.delivered:
      return 'DELIVERED';
    case BookingStatus.completed:
      return 'COMPLETED';
    case BookingStatus.cancelled:
      return 'CANCELLED';
  }
}

Shift shiftFromServer(Object? raw, {Shift fallback = Shift.day}) {
  if (raw == null) return fallback;
  final n = _normalizeEnum(raw.toString());
  for (final s in Shift.values) {
    if (_normalizeEnum(s.name) == n) return s;
  }
  return fallback;
}

String shiftToServer(Shift s) {
  switch (s) {
    case Shift.day:
      return 'DAY';
    case Shift.night:
      return 'NIGHT';
    case Shift.both:
      return 'BOTH';
  }
}

EventType eventTypeFromServer(
  Object? raw, {
  EventType fallback = EventType.other,
}) {
  if (raw == null) return fallback;
  final n = _normalizeEnum(raw.toString());
  for (final t in EventType.values) {
    if (_normalizeEnum(t.name) == n) return t;
  }
  return fallback;
}

// ───────────────────────── Booking ─────────────────────────

/// Maps a Laravel `events` row (BookingResource output) to a [Booking].
///
/// [fallback] is the local copy when one exists (create/patch responses,
/// pull-merge). Local `id` and the fields the server does not persist are
/// taken from it so a sync round-trip never wipes locally-entered data.
Booking bookingFromServer(Map<String, dynamic> j, {Booking? fallback}) {
  final serverId = serverString(j, ['id']);
  final ownerId = serverString(j, ['owner_id', 'ownerId', 'studioId']);

  return Booking(
    id: fallback?.id ?? serverId ?? '',
    remoteId: serverId ?? fallback?.remoteId,
    studioId: ownerId ?? fallback?.studioId ?? '',
    createdByUserId: ownerId ?? fallback?.createdByUserId ?? '',
    title: serverString(j, ['title']) ?? fallback?.title ?? '',
    eventType: j.containsKey('event_type') || j.containsKey('eventType')
        ? eventTypeFromServer(
            j['event_type'] ?? j['eventType'],
            fallback: fallback?.eventType ?? EventType.other,
          )
        : fallback?.eventType ?? EventType.other,
    date: serverDate(j['date']) ?? fallback?.date ?? DateTime.now(),
    // The Laravel schema has no time columns — keep the local values.
    startTime: fallback?.startTime ?? '10:00',
    endTime: fallback?.endTime ?? '18:00',
    shift: j.containsKey('shift')
        ? shiftFromServer(j['shift'], fallback: fallback?.shift ?? Shift.day)
        : fallback?.shift ?? Shift.day,
    venue: serverString(j, ['venue']) ?? fallback?.venue,
    outdoor: fallback?.outdoor ?? false,
    brideName: fallback?.brideName,
    groomName: fallback?.groomName,
    clientId: serverString(j, ['client_id', 'clientId']) ?? fallback?.clientId,
    clientName:
        serverString(j, ['client_name', 'clientName']) ?? fallback?.clientName,
    clientPhone:
        serverString(j, ['client_phone', 'clientPhone']) ??
        fallback?.clientPhone,
    packageId:
        serverString(j, ['package_id', 'packageId']) ?? fallback?.packageId,
    customPrice:
        serverDouble(j['price'] ?? j['customPrice']) ?? fallback?.customPrice,
    coverageHours: fallback?.coverageHours,
    extraHourRate: fallback?.extraHourRate,
    driveLink: fallback?.driveLink,
    clientRequirements: fallback?.clientRequirements,
    notes: serverString(j, ['notes']) ?? fallback?.notes,
    chiefPhotographerUserId: fallback?.chiefPhotographerUserId,
    chiefHours: fallback?.chiefHours,
    hidePaymentFromTeam: fallback?.hidePaymentFromTeam ?? false,
    status: j.containsKey('status')
        ? bookingStatusFromServer(
            j['status'],
            fallback: fallback?.status ?? BookingStatus.pending,
          )
        : fallback?.status ?? BookingStatus.pending,
    createdAt:
        serverDate(j['created_at'] ?? j['createdAt']) ??
        fallback?.createdAt ??
        DateTime.now(),
    updatedAt:
        serverDate(j['updated_at'] ?? j['updatedAt']) ??
        fallback?.updatedAt ??
        DateTime.now(),
    pending: false,
  );
}

/// Maps a [Booking] to the request body the Laravel `BookingRequest`
/// validates (snake_case; only the columns the server persists).
///
/// `client_name` / `client_phone` are sent so the backend resolves or
/// creates the Client row server-side (its own contract); the local
/// client UUID is meaningless to the server and is never sent.
Map<String, dynamic> bookingToServer(Booking b) {
  return <String, dynamic>{
    'title': b.title,
    'date': b.date.toIso8601String().split('T').first,
    'event_type': b.eventType.name,
    'shift': shiftToServer(b.shift),
    'status': bookingStatusToServer(b.status),
    if (b.venue != null) 'venue': b.venue,
    if (b.customPrice != null) 'price': b.customPrice,
    if (b.notes != null) 'notes': b.notes,
    if (b.clientName != null) 'client_name': b.clientName,
    if (b.clientPhone != null) 'client_phone': b.clientPhone,
  };
}

// ───────────────────────── Client ─────────────────────────

Client clientFromServer(Map<String, dynamic> j, {Client? fallback}) {
  final serverId = serverString(j, ['id']);
  final ownerId = serverString(j, ['owner_id', 'ownerId', 'studioId']);

  return Client(
    id: fallback?.id ?? serverId ?? '',
    remoteId: serverId ?? fallback?.remoteId,
    studioId: ownerId ?? fallback?.studioId ?? '',
    name: serverString(j, ['name']) ?? fallback?.name ?? '',
    phone: serverString(j, ['phone']) ?? fallback?.phone ?? '',
    email: serverString(j, ['email']) ?? fallback?.email,
    address: fallback?.address,
    dob: fallback?.dob,
    anniversary: fallback?.anniversary,
    createdAt:
        serverDate(j['created_at'] ?? j['createdAt']) ??
        fallback?.createdAt ??
        DateTime.now(),
    updatedAt:
        serverDate(j['updated_at'] ?? j['updatedAt']) ??
        fallback?.updatedAt ??
        DateTime.now(),
    pending: false,
  );
}

/// Request body for the Laravel `ClientRequest` (name/phone/email only —
/// the server schema has no address/dob/anniversary columns).
Map<String, dynamic> clientToServer(Client c) {
  return <String, dynamic>{
    'name': c.name,
    if (c.phone.isNotEmpty) 'phone': c.phone,
    if (c.email != null) 'email': c.email,
  };
}

// ───────────────────────── Status history ─────────────────────────

/// Maps a Laravel `status_histories` row to a local timeline entry.
/// [bookingLocalId] is the LOCAL booking id the entry hangs off.
StatusHistoryEntry statusEntryFromServer(
  Map<String, dynamic> j, {
  required String bookingLocalId,
}) {
  final serverId = serverString(j, ['id']);
  return StatusHistoryEntry(
    id: serverId ?? 'sh_${DateTime.now().microsecondsSinceEpoch}',
    remoteId: serverId,
    bookingId: bookingLocalId,
    fromStatus: bookingStatusFromServer(j['from_status'] ?? j['fromStatus']),
    toStatus: bookingStatusFromServer(j['to_status'] ?? j['toStatus']),
    changedByUserId:
        serverString(j, ['changed_by', 'changedByUserId', 'changed_by_user_id']) ??
        '',
    note: serverString(j, ['note']),
    at: serverDate(j['created_at'] ?? j['at']) ?? DateTime.now(),
    pending: false,
  );
}
