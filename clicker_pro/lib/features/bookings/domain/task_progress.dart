// lib/features/bookings/domain/task_progress.dart
//
// Domain entity for a per-staff-per-booking task progress record. The
// composite key `(bookingId, userId)` is the primary key — there is at
// most one progress row per (booking, user) pair, and `upsert` is the
// only legal write operation.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 8.1–8.5, 13.13.

/// Progress on a booking-scoped task tracked per assigned team member.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
/// Identity is the `(bookingId, userId)` pair — no UUID — so equality and
/// hash are computed over those two fields plus the mutable shape.
class TaskProgress {
  /// Local id of the parent [Booking].
  final String bookingId;

  /// Local id of the team member this progress row tracks.
  final String userId;

  /// Completion percentage in `[0, 100]`. Validated at the controller
  /// layer; stored verbatim so out-of-range values surface in tests
  /// rather than silently clamping.
  final int percentage;

  /// Free-form note attached to the progress entry.
  final String? note;

  /// Most recent edit timestamp; reconciled via last-write-wins.
  final DateTime updatedAt;

  /// True while the progress row has unsynced changes in the outbox.
  final bool pending;

  TaskProgress({
    required this.bookingId,
    required this.userId,
    required this.percentage,
    this.note,
    required this.updatedAt,
    this.pending = false,
  });

  TaskProgress copyWith({
    String? bookingId,
    String? userId,
    int? percentage,
    String? note,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return TaskProgress(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      percentage: percentage ?? this.percentage,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bookingId': bookingId,
      'userId': userId,
      'percentage': percentage,
      if (note != null) 'note': note,
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      percentage: (json['percentage'] as num).toInt(),
      note: json['note'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskProgress) return false;
    return bookingId == other.bookingId &&
        userId == other.userId &&
        percentage == other.percentage &&
        note == other.note &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    bookingId,
    userId,
    percentage,
    note,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'TaskProgress(bookingId: $bookingId, userId: $userId, '
      'percentage: $percentage)';
}
