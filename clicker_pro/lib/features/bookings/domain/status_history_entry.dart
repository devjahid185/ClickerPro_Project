// lib/features/bookings/domain/status_history_entry.dart
//
// Domain entity for a single row in a booking's status timeline.
// Tier C — append-only. Once a status entry is written it is never
// updated; the only mutation is the local `pending` flag flipping to
// `false` after the outbox worker drains successfully.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 3.1–3.11, 13.6.

import '../../../core/booking_status/booking_status.dart';

/// One entry in a booking's append-only status history timeline.
///
/// Instances are immutable; use [copyWith] sparingly — the only legal
/// mutation is the local [pending] flag flipping to `false` after sync.
class StatusHistoryEntry {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Local id of the parent [Booking].
  final String bookingId;

  /// Status the booking transitioned out of.
  final BookingStatus fromStatus;

  /// Status the booking transitioned into.
  final BookingStatus toStatus;

  /// Local id of the user who initiated the transition.
  final String changedByUserId;

  /// Optional note attached to the transition (e.g. cancel reason).
  final String? note;

  /// Wall-clock timestamp the transition was recorded. Set client-side
  /// at the moment the status repository commits the row.
  final DateTime at;

  /// True while the entry has not yet been confirmed by the server. On
  /// 409 conflict the local pending row is dropped — never updated.
  final bool pending;

  StatusHistoryEntry({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedByUserId,
    this.note,
    required this.at,
    this.pending = false,
  });

  StatusHistoryEntry copyWith({
    String? id,
    String? remoteId,
    String? bookingId,
    BookingStatus? fromStatus,
    BookingStatus? toStatus,
    String? changedByUserId,
    String? note,
    DateTime? at,
    bool? pending,
  }) {
    return StatusHistoryEntry(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      note: note ?? this.note,
      at: at ?? this.at,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'bookingId': bookingId,
      'fromStatus': fromStatus.name,
      'toStatus': toStatus.name,
      'changedByUserId': changedByUserId,
      if (note != null) 'note': note,
      'at': at.toIso8601String(),
      'pending': pending,
    };
  }

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      bookingId: json['bookingId'] as String,
      fromStatus: BookingStatus.values.firstWhere(
        (s) => s.name == json['fromStatus'] as String,
        orElse: () => BookingStatus.pending,
      ),
      toStatus: BookingStatus.values.firstWhere(
        (s) => s.name == json['toStatus'] as String,
        orElse: () => BookingStatus.pending,
      ),
      changedByUserId: json['changedByUserId'] as String,
      note: json['note'] as String?,
      at: DateTime.parse(json['at'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StatusHistoryEntry) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        bookingId == other.bookingId &&
        fromStatus == other.fromStatus &&
        toStatus == other.toStatus &&
        changedByUserId == other.changedByUserId &&
        note == other.note &&
        at == other.at &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    bookingId,
    fromStatus,
    toStatus,
    changedByUserId,
    note,
    at,
    pending,
  ]);

  @override
  String toString() =>
      'StatusHistoryEntry(id: $id, bookingId: $bookingId, '
      '${fromStatus.name} -> ${toStatus.name}, at: $at)';
}
