// lib/features/bookings/domain/assignment.dart
//
// Domain entity for an Assignment — pins a team member to a specific
// on-shoot role on a single booking. Independent of [UserRole]: a
// freelancer user can be pinned as the cinematographer on one booking
// and the editor on another.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 7.4, 13.9.

import 'assignment_role.dart';

/// A team member's assignment to a booking in a specific on-shoot role.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
class Assignment {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Local id of the parent [Booking].
  final String bookingId;

  /// Local id of the assigned team member.
  final String userId;

  /// On-shoot role this assignment fills.
  final AssignmentRole role;

  /// Payout amount for this assignment. Stored as a `double` for
  /// presentation parity with [Payment.amount]; rounding happens at
  /// display time.
  final double payout;

  /// Free-form notes attached to the assignment.
  final String? notes;

  /// Wall-clock timestamp at first creation.
  final DateTime createdAt;

  /// Most recent edit timestamp; reconciled via last-write-wins.
  final DateTime updatedAt;

  /// True while the assignment has unsynced changes in the outbox.
  final bool pending;

  Assignment({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.userId,
    required this.role,
    this.payout = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
  });

  Assignment copyWith({
    String? id,
    String? remoteId,
    String? bookingId,
    String? userId,
    AssignmentRole? role,
    double? payout,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return Assignment(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      payout: payout ?? this.payout,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'bookingId': bookingId,
      'userId': userId,
      'role': role.name,
      'payout': payout,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      role: AssignmentRole.values.firstWhere(
        (r) => r.name == json['role'] as String,
        orElse: () => AssignmentRole.assistant,
      ),
      payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Assignment) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        bookingId == other.bookingId &&
        userId == other.userId &&
        role == other.role &&
        payout == other.payout &&
        notes == other.notes &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    bookingId,
    userId,
    role,
    payout,
    notes,
    createdAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'Assignment(id: $id, bookingId: $bookingId, userId: $userId, '
      'role: ${role.name}, payout: $payout)';
}
