// lib/features/freelancer/domain/fl_leave_request.dart
//
// Domain entity for a Freelancer Leave Request (FL-07).
// Freelancers submit formal leave requests; owners approve/deny
// and successful approval auto-creates blackout dates.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

/// Lifecycle status of a leave request.
enum LeaveRequestStatus {
  pending,
  approved,
  denied,
  cancelled;

  static LeaveRequestStatus fromString(String value) {
    for (final s in LeaveRequestStatus.values) {
      if (s.name == value) return s;
    }
    return LeaveRequestStatus.pending;
  }

  bool get isTerminal => this == approved || this == denied;
}

/// A formal leave request from a freelancer to an owner.
class FlLeaveRequest {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// The freelancer who submitted the request.
  final String freelancerId;

  /// The owner who receives the request.
  final String ownerId;

  /// Start date of the requested leave (inclusive).
  final DateTime startDate;

  /// End date of the requested leave (inclusive).
  final DateTime endDate;

  /// Free-form reason for the leave (e.g. "Family vacation", "Medical").
  final String reason;

  /// Optional additional notes from the freelancer.
  final String? notes;

  /// Current lifecycle status.
  final LeaveRequestStatus status;

  /// Owner's response note when approving or denying. Null while pending.
  final String? ownerResponse;

  /// Wall-clock timestamp at creation.
  final DateTime createdAt;

  /// Most recent edit timestamp.
  final DateTime updatedAt;

  const FlLeaveRequest({
    required this.id,
    this.remoteId,
    required this.freelancerId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.notes,
    this.status = LeaveRequestStatus.pending,
    this.ownerResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Number of calendar days covered by the request.
  int get durationDays => endDate.difference(startDate).inDays + 1;

  FlLeaveRequest copyWith({
    String? id,
    String? remoteId,
    String? freelancerId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? notes,
    LeaveRequestStatus? status,
    String? ownerResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlLeaveRequest(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      freelancerId: freelancerId ?? this.freelancerId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      ownerResponse: ownerResponse ?? this.ownerResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'freelancerId': freelancerId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      if (notes != null) 'notes': notes,
      'status': status.name,
      if (ownerResponse != null) 'ownerResponse': ownerResponse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlLeaveRequest.fromJson(Map<String, dynamic> json) {
    return FlLeaveRequest(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      freelancerId: json['freelancerId'] as String,
      ownerId: json['ownerId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      status: LeaveRequestStatus.fromString(
        (json['status'] as String?) ?? 'pending',
      ),
      ownerResponse: json['ownerResponse'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlLeaveRequest) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        freelancerId == other.freelancerId &&
        ownerId == other.ownerId &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        reason == other.reason &&
        notes == other.notes &&
        status == other.status &&
        ownerResponse == other.ownerResponse &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    freelancerId,
    ownerId,
    startDate,
    endDate,
    reason,
    notes,
    status,
    ownerResponse,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'FlLeaveRequest(id: $id, status: ${status.name}, '
      'startDate: $startDate, endDate: $endDate)';
}
