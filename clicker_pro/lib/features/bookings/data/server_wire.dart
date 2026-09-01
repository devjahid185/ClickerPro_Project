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

import 'dart:convert';

import '../../../core/booking_status/booking_status.dart';
import '../domain/assignment.dart';
import '../domain/assignment_role.dart';
import '../domain/booking.dart';
import '../domain/client.dart';
import '../domain/event_type.dart';
import '../domain/package.dart';
import '../domain/payment.dart';
import '../domain/payment_kind.dart';
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

int? serverInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool? serverBool(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == '1' || s == 'true' || s == 'yes') return true;
  if (s == '0' || s == 'false' || s == 'no') return false;
  return null;
}

List<String>? serverStringList(Object? v) {
  if (v == null) return null;
  if (v is List) {
    final items = v
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }
  final text = v.toString().trim();
  if (text.isEmpty) return null;
  try {
    final decoded = jsonDecode(text);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
  } catch (_) {
    // Fall through to comma/newline separated text.
  }
  final items = text
      .split(RegExp(r'[\r\n,]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  return items.isEmpty ? null : items;
}

DateTime? serverDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// The event `date` column is a calendar date (the shoot day), not an instant.
/// Laravel's `date` cast serializes it as an ISO instant at UTC midnight
/// ("2026-07-08T00:00:00.000000Z"). If that is parsed and later converted to
/// local time for display it bleeds a spurious clock offset onto the date
/// (e.g. "06:00" in Bangladesh) and, in negative-offset zones, can even shift
/// the day. Collapse it back to a pure local calendar date so every surface
/// renders the same, time-free day. The DateTime's own components already hold
/// the intended day (UTC fields for a "…Z" value, local fields for a naive
/// one), so reading them directly is correct either way.
DateTime? serverEventDate(Object? v) {
  final d = serverDate(v);
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day);
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

/// Decodes the server `requirements_note` column back into the local
/// `clientRequirements` map. The server stores it as a JSON string (encoded
/// in [bookingToServer]); older rows or hand-entered text are kept as a
/// `{'note': <text>}` map so nothing is lost. Returns [fallback] when empty.
Map<String, dynamic>? _requirementsFromServer(
  Object? raw, {
  Map<String, dynamic>? fallback,
}) {
  if (raw == null) return fallback;
  final text = raw.toString().trim();
  if (text.isEmpty) return fallback;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    // Not JSON — treat as a plain note.
  }
  return {'note': text};
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
    createdByUserId: fallback?.createdByUserId ?? ownerId ?? '',
    title: serverString(j, ['title']) ?? fallback?.title ?? '',
    eventType: j.containsKey('event_type') || j.containsKey('eventType')
        ? eventTypeFromServer(
            j['event_type'] ?? j['eventType'],
            fallback: fallback?.eventType ?? EventType.other,
          )
        : fallback?.eventType ?? EventType.other,
    date: serverEventDate(j['date']) ?? fallback?.date ?? DateTime.now(),
    startTime:
        serverString(j, ['start_time', 'startTime']) ??
        fallback?.startTime ??
        '10:00',
    endTime:
        serverString(j, ['end_time', 'endTime']) ??
        fallback?.endTime ??
        '18:00',
    shift: j.containsKey('shift')
        ? shiftFromServer(j['shift'], fallback: fallback?.shift ?? Shift.day)
        : fallback?.shift ?? Shift.day,
    venue: serverString(j, ['venue']) ?? fallback?.venue,
    outdoor: j.containsKey('outdoor')
        ? (j['outdoor'] == true || j['outdoor'] == 1 || j['outdoor'] == '1')
        : fallback?.outdoor ?? false,
    brideName:
        serverString(j, ['bride_name', 'brideName']) ?? fallback?.brideName,
    groomName:
        serverString(j, ['groom_name', 'groomName']) ?? fallback?.groomName,
    clientId: serverString(j, ['client_id', 'clientId']) ?? fallback?.clientId,
    clientName:
        serverString(j, ['client_name', 'clientName']) ?? fallback?.clientName,
    clientPhone:
        serverString(j, ['client_phone', 'clientPhone']) ??
        fallback?.clientPhone,
    packageId:
        serverString(j, ['package_id', 'packageId']) ?? fallback?.packageId,
    customPrice:
        serverDouble(j['custom_price'] ?? j['price'] ?? j['customPrice']) ??
        fallback?.customPrice,
    coverageHours:
        serverDouble(j['coverage_hours'] ?? j['coverageHours']) ??
        fallback?.coverageHours,
    extraHourRate:
        serverDouble(j['extra_hour_rate'] ?? j['extraHourRate']) ??
        fallback?.extraHourRate,
    driveLink:
        serverString(j, ['drive_link', 'driveLink']) ?? fallback?.driveLink,
    clientRequirements: _requirementsFromServer(
      j['requirements_note'] ?? j['requirementsNote'],
      fallback: fallback?.clientRequirements,
    ),
    notes: serverString(j, ['notes']) ?? fallback?.notes,
    chiefPhotographerUserId:
        serverString(j, ['chief_photographer_name', 'chiefPhotographerName']) ??
        fallback?.chiefPhotographerUserId,
    chiefHours: fallback?.chiefHours,
    hidePaymentFromTeam: j.containsKey('hide_payment_from_team')
        ? (j['hide_payment_from_team'] == true ||
              j['hide_payment_from_team'] == 1 ||
              j['hide_payment_from_team'] == '1')
        : fallback?.hidePaymentFromTeam ?? false,
    showPaymentInShare: j.containsKey('show_payment_in_share')
        ? (j['show_payment_in_share'] == true ||
              j['show_payment_in_share'] == 1 ||
              j['show_payment_in_share'] == '1')
        : fallback?.showPaymentInShare ?? false,
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
    if (b.packageId != null)
      'package_id': int.tryParse(b.packageId!) ?? b.packageId,
    if (b.customPrice != null) 'price': b.customPrice,
    if (b.notes != null) 'notes': b.notes,
    if (b.clientName != null) 'client_name': b.clientName,
    if (b.clientPhone != null) 'client_phone': b.clientPhone,
    // Rich detail fields — now persisted server-side for mobile↔web parity.
    'outdoor': b.outdoor,
    'hide_payment_from_team': b.hidePaymentFromTeam,
    'show_payment_in_share': b.showPaymentInShare,
    if (b.brideName != null) 'bride_name': b.brideName,
    if (b.groomName != null) 'groom_name': b.groomName,
    if (b.startTime.isNotEmpty) 'start_time': b.startTime,
    if (b.endTime.isNotEmpty) 'end_time': b.endTime,
    if (b.coverageHours != null) 'coverage_hours': b.coverageHours,
    if (b.extraHourRate != null) 'extra_hour_rate': b.extraHourRate,
    if (b.customPrice != null) 'custom_price': b.customPrice,
    if (b.driveLink != null) 'drive_link': b.driveLink,
    if (b.chiefPhotographerUserId != null)
      'chief_photographer_name': b.chiefPhotographerUserId,
    if (b.clientRequirements != null)
      'requirements_note': jsonEncode(b.clientRequirements),
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

// ───────────────────────── Payment ─────────────────────────

PaymentKind paymentKindFromServer(
  Object? raw, {
  PaymentKind fallback = PaymentKind.advance,
}) {
  if (raw == null) return fallback;
  final n = _normalizeEnum(raw.toString());
  for (final k in PaymentKind.values) {
    if (_normalizeEnum(k.name) == n) return k;
  }
  // The server also knows PAYOUT (freelancer payouts) — closest local
  // bucket is `extra` so the money still tallies somewhere visible.
  if (n == 'payout') return PaymentKind.extra;
  return fallback;
}

String paymentKindToServer(PaymentKind k) {
  switch (k) {
    case PaymentKind.advance:
      return 'ADVANCE';
    case PaymentKind.due:
      return 'DUE';
    case PaymentKind.paid:
      return 'PAID';
    case PaymentKind.extra:
      return 'EXTRA';
  }
}

/// Laravel validates method against CASH/BKASH/NAGAD/BANK/CARD/OTHER.
String? paymentMethodToServer(String? method) {
  if (method == null || method.trim().isEmpty) return null;
  const allowed = {'CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD', 'OTHER'};
  final upper = method.trim().toUpperCase();
  return allowed.contains(upper) ? upper : 'OTHER';
}

/// Maps a Laravel `payments` row to a local [Payment]. [bookingLocalId]
/// is the LOCAL booking the payment hangs off.
Payment paymentFromServer(
  Map<String, dynamic> j, {
  required String bookingLocalId,
  Payment? fallback,
}) {
  final serverId = serverString(j, ['id']);
  return Payment(
    id: fallback?.id ?? serverId ?? '',
    remoteId: serverId ?? fallback?.remoteId,
    bookingId: bookingLocalId,
    kind: paymentKindFromServer(
      j['kind'],
      fallback: fallback?.kind ?? PaymentKind.advance,
    ),
    amount: serverDouble(j['amount']) ?? fallback?.amount ?? 0,
    method: serverString(j, ['method'])?.toLowerCase() ?? fallback?.method,
    note: serverString(j, ['note']) ?? fallback?.note,
    paidAt: serverDate(j['paid_at'] ?? j['paidAt']) ?? fallback?.paidAt,
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

/// Request body for `POST /api/payments` (PaymentController::store).
Map<String, dynamic> paymentToServer(
  Payment p, {
  required String eventRemoteId,
}) {
  return <String, dynamic>{
    'event_id': int.tryParse(eventRemoteId) ?? eventRemoteId,
    'amount': p.amount,
    'kind': paymentKindToServer(p.kind),
    'method': ?paymentMethodToServer(p.method),
    'note': ?p.note,
    if (p.paidAt != null)
      'paid_at': p.paidAt!.toIso8601String().split('T').first,
  };
}

// ───────────────────────── Assignment ─────────────────────────

AssignmentRole assignmentRoleFromServer(
  Object? raw, {
  AssignmentRole fallback = AssignmentRole.assistant,
}) {
  if (raw == null) return fallback;
  final n = _normalizeEnum(raw.toString());
  for (final r in AssignmentRole.values) {
    if (_normalizeEnum(r.name) == n) return r;
  }
  return fallback;
}

/// Maps a Laravel `assignments` row to a local [Assignment].
/// [bookingLocalId] is the LOCAL booking the row hangs off.
Assignment assignmentFromServer(
  Map<String, dynamic> j, {
  required String bookingLocalId,
  Assignment? fallback,
}) {
  final serverId = serverString(j, ['id']);
  return Assignment(
    id: fallback?.id ?? serverId ?? '',
    remoteId: serverId ?? fallback?.remoteId,
    bookingId: bookingLocalId,
    userId: serverString(j, ['user_id', 'userId']) ?? fallback?.userId ?? '',
    role: assignmentRoleFromServer(
      j['role'],
      fallback: fallback?.role ?? AssignmentRole.assistant,
    ),
    payout: serverDouble(j['payout']) ?? fallback?.payout ?? 0,
    notes: serverString(j, ['notes']) ?? fallback?.notes,
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

/// Request body for the Laravel AssignmentController. The local userId
/// must already be a server user id (team members sync down with server
/// ids) — a non-numeric local-only id is sent as-is and rejected with a
/// clean 422 rather than corrupting data.
Map<String, dynamic> assignmentToServer(Assignment a) {
  return <String, dynamic>{
    'user_id': int.tryParse(a.userId) ?? a.userId,
    'role': a.role.name,
    'payout': a.payout,
    'notes': ?a.notes,
  };
}

// ───────────────────────── Package ─────────────────────────

/// Maps a Laravel `packages` row to a local [Package]. The server only
/// persists name/base_price/coverage_hours (+ a few booleans) — the rich
/// local fields (prints, albums, trailers, items…) come from [fallback].
Package packageFromServer(Map<String, dynamic> j, {Package? fallback}) {
  final serverId = serverString(j, ['id']);
  return Package(
    id: fallback?.id ?? serverId ?? '',
    remoteId: serverId ?? fallback?.remoteId,
    studioId:
        serverString(j, ['owner_id', 'ownerId', 'studioId']) ??
        fallback?.studioId ??
        '',
    name: serverString(j, ['name']) ?? fallback?.name ?? '',
    basePrice:
        serverDouble(j['base_price'] ?? j['basePrice'] ?? j['price']) ??
        fallback?.basePrice ??
        0,
    discount: serverDouble(j['discount']) ?? fallback?.discount ?? 0,
    coverageHours:
        serverDouble(j['coverage_hours'] ?? j['coverageHours']) ??
        fallback?.coverageHours,
    extraHourRate:
        serverDouble(j['extra_hour_rate'] ?? j['extraHourRate']) ??
        fallback?.extraHourRate,
    printSize:
        serverString(j, ['print_size', 'printSize']) ?? fallback?.printSize,
    printQuantity:
        serverInt(j['print_quantity'] ?? j['printQuantity']) ??
        fallback?.printQuantity,
    albumText:
        serverString(j, ['album_text', 'albumText']) ?? fallback?.albumText,
    deliveryMethod:
        serverString(j, ['delivery_method', 'deliveryMethod']) ??
        fallback?.deliveryMethod,
    trailersPerEvent:
        serverInt(j['trailers_per_event'] ?? j['trailersPerEvent']) ??
        fallback?.trailersPerEvent,
    fullVideosPerEvent:
        serverInt(j['full_videos_per_event'] ?? j['fullVideosPerEvent']) ??
        fallback?.fullVideosPerEvent,
    photographerCount:
        serverInt(j['photographer_count'] ?? j['photographerCount']) ??
        fallback?.photographerCount,
    cinematographerCount:
        serverInt(j['cinematographer_count'] ?? j['cinematographerCount']) ??
        fallback?.cinematographerCount,
    includesChief:
        serverBool(j['includes_chief'] ?? j['includesChief']) ??
        fallback?.includesChief ??
        false,
    items: serverStringList(j['items']) ?? fallback?.items,
    inclusions: serverStringList(j['inclusions']) ?? fallback?.inclusions,
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

/// Request body for the Laravel PackageController.
Map<String, dynamic> packageToServer(Package p) {
  return <String, dynamic>{
    'name': p.name,
    'base_price': p.basePrice,
    'price': p.basePrice,
    'discount': p.discount,
    if (p.coverageHours != null) 'coverage_hours': p.coverageHours!.round(),
    if (p.extraHourRate != null) 'extra_hour_rate': p.extraHourRate,
    if (p.printSize != null) 'print_size': p.printSize,
    if (p.printQuantity != null) 'print_quantity': p.printQuantity,
    if (p.albumText != null) 'album_text': p.albumText,
    if (p.deliveryMethod != null) 'delivery_method': p.deliveryMethod,
    if (p.trailersPerEvent != null) 'trailers_per_event': p.trailersPerEvent,
    if (p.fullVideosPerEvent != null)
      'full_videos_per_event': p.fullVideosPerEvent,
    if (p.photographerCount != null) 'photographer_count': p.photographerCount,
    if (p.cinematographerCount != null)
      'cinematographer_count': p.cinematographerCount,
    'includes_chief': p.includesChief,
    if (p.items != null) 'items': p.items,
    if (p.inclusions != null) 'inclusions': p.inclusions,
    if (p.fullVideosPerEvent != null) 'has_video': p.fullVideosPerEvent! > 0,
    if (p.albumText != null && p.albumText!.trim().isNotEmpty)
      'has_album': true,
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
        serverString(j, [
          'changed_by',
          'changedByUserId',
          'changed_by_user_id',
        ]) ??
        '',
    note: serverString(j, ['note']),
    at: serverDate(j['created_at'] ?? j['at']) ?? DateTime.now(),
    pending: false,
  );
}
