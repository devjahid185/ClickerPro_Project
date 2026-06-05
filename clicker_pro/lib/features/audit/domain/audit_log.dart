// lib/features/audit/domain/audit_log.dart
//
// Domain entity for an audit log entry. Tracks who did what,
// on which entity, with before/after state for diff views.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

enum AuditAction { create, update, delete, permission }

class AuditLogEntry {
  final String id;
  final String actorId;
  final String actorName;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final String? entityLabel;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.entityLabel,
    this.before,
    this.after,
    required this.createdAt,
  });

  AuditLogEntry copyWith({
    String? id,
    String? actorId,
    String? actorName,
    AuditAction? action,
    String? entityType,
    String? entityId,
    String? entityLabel,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    DateTime? createdAt,
  }) {
    return AuditLogEntry(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityLabel: entityLabel ?? this.entityLabel,
      before: before ?? this.before,
      after: after ?? this.after,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get actionLabel {
    switch (action) {
      case AuditAction.create:
        return 'Created';
      case AuditAction.update:
        return 'Updated';
      case AuditAction.delete:
        return 'Deleted';
      case AuditAction.permission:
        return 'Permission changed';
    }
  }

  String get actionVerb {
    switch (action) {
      case AuditAction.create:
        return 'created';
      case AuditAction.update:
        return 'updated';
      case AuditAction.delete:
        return 'deleted';
      case AuditAction.permission:
        return 'changed permissions on';
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'actorId': actorId,
      'actorName': actorName,
      'action': action.name,
      'entityType': entityType,
      'entityId': entityId,
      if (entityLabel != null) 'entityLabel': entityLabel,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      action: AuditAction.values.firstWhere(
        (a) => a.name == json['action'] as String,
        orElse: () => AuditAction.update,
      ),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      entityLabel: json['entityLabel'] as String?,
      before: json['before'] as Map<String, dynamic>?,
      after: json['after'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuditLogEntry) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AuditLogEntry(id: $id, actor: $actorName, action: ${action.name}, '
      'entity: $entityType/$entityId)';
}
