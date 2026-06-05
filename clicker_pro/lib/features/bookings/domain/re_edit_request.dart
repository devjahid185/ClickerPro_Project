// lib/features/bookings/domain/re_edit_request.dart
//
// Domain entity for a Re-edit Request — a follow-up edit round opened
// against a delivered booking. Tracks the round number, the assigned
// editor, the deadline, optional reference image URLs, and a lifecycle
// status that can become "overdue" once the deadline passes.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports. The [isOverdue]
// getter calls [DateTime.now] which is deterministic-friendly for tests
// because callers can just pin the system clock.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 7.1–7.7, 13.12.

import 're_edit_status.dart';

/// A re-edit request raised against a delivered booking.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
/// The `(bookingId, round)` pair is unique — round is the 1-based ordinal
/// of this request within its booking.
class ReEditRequest {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Local id of the parent [Booking].
  final String bookingId;

  /// 1-based ordinal of this request within its booking. Computed by
  /// `ReEditRepository.nextRoundFor(bookingId)`.
  final int round;

  /// Local id of the editor assigned to this round. `null` while the
  /// request is unassigned.
  final String? editorUserId;

  /// Wall-clock deadline for completion. Drives [isOverdue].
  final DateTime deadline;

  /// Optional list of reference image URLs the requester attached.
  final List<String>? referenceImageUrls;

  /// Free-form notes from the requester (typically the Owner / Manager).
  final String? notes;

  /// Lifecycle status. Transitions: `pending -> inProgress -> done`, or
  /// `pending -> rejected`.
  final ReEditStatus status;

  /// Local id of the user who raised the request.
  final String requestedByUserId;

  /// When the request was raised.
  final DateTime requestedAt;

  /// Most recent edit timestamp; reconciled via last-write-wins for the
  /// request meta (status changes themselves are append-only Tier C).
  final DateTime updatedAt;

  /// True while the request has unsynced changes in the outbox.
  final bool pending;

  ReEditRequest({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.round,
    this.editorUserId,
    required this.deadline,
    this.referenceImageUrls,
    this.notes,
    required this.status,
    required this.requestedByUserId,
    required this.requestedAt,
    required this.updatedAt,
    this.pending = false,
  });

  /// True iff this request is open (pending or in-progress) AND its
  /// [deadline] has already passed. Read-only — the request becomes
  /// "not overdue" again the moment its [status] flips to `done` or
  /// `rejected`.
  bool get isOverdue =>
      (status == ReEditStatus.pending || status == ReEditStatus.inProgress) &&
      deadline.isBefore(DateTime.now());

  ReEditRequest copyWith({
    String? id,
    String? remoteId,
    String? bookingId,
    int? round,
    String? editorUserId,
    DateTime? deadline,
    List<String>? referenceImageUrls,
    String? notes,
    ReEditStatus? status,
    String? requestedByUserId,
    DateTime? requestedAt,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return ReEditRequest(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      round: round ?? this.round,
      editorUserId: editorUserId ?? this.editorUserId,
      deadline: deadline ?? this.deadline,
      referenceImageUrls: referenceImageUrls ?? this.referenceImageUrls,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'bookingId': bookingId,
      'round': round,
      if (editorUserId != null) 'editorUserId': editorUserId,
      'deadline': deadline.toIso8601String(),
      if (referenceImageUrls != null) 'referenceImageUrls': referenceImageUrls,
      if (notes != null) 'notes': notes,
      'status': status.name,
      'requestedByUserId': requestedByUserId,
      'requestedAt': requestedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory ReEditRequest.fromJson(Map<String, dynamic> json) {
    return ReEditRequest(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      bookingId: json['bookingId'] as String,
      round: (json['round'] as num).toInt(),
      editorUserId: json['editorUserId'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      referenceImageUrls: json['referenceImageUrls'] == null
          ? null
          : List<String>.from(json['referenceImageUrls'] as List),
      notes: json['notes'] as String?,
      status: ReEditStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => ReEditStatus.pending,
      ),
      requestedByUserId: json['requestedByUserId'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReEditRequest) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        bookingId == other.bookingId &&
        round == other.round &&
        editorUserId == other.editorUserId &&
        deadline == other.deadline &&
        _listEquals(referenceImageUrls, other.referenceImageUrls) &&
        notes == other.notes &&
        status == other.status &&
        requestedByUserId == other.requestedByUserId &&
        requestedAt == other.requestedAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    bookingId,
    round,
    editorUserId,
    deadline,
    referenceImageUrls == null ? 0 : Object.hashAll(referenceImageUrls!),
    notes,
    status,
    requestedByUserId,
    requestedAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'ReEditRequest(id: $id, bookingId: $bookingId, round: $round, '
      'status: ${status.name}, deadline: $deadline)';
}

/// Order-sensitive list equality used for [ReEditRequest.referenceImageUrls].
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
