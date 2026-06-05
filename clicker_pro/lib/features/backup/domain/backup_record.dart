// lib/features/backup/domain/backup_record.dart
//
// Domain entity for a database backup record. Tracks type, size,
// creation timestamp, and backup status.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

enum BackupType { daily, weekly, manual }

enum BackupStatus { pending, inProgress, completed, failed }

class BackupRecord {
  final String id;
  final BackupType type;
  final int sizeBytes;
  final DateTime createdAt;
  final BackupStatus status;
  final String? filePath;
  final String? error;

  const BackupRecord({
    required this.id,
    required this.type,
    required this.sizeBytes,
    required this.createdAt,
    required this.status,
    this.filePath,
    this.error,
  });

  BackupRecord copyWith({
    String? id,
    BackupType? type,
    int? sizeBytes,
    DateTime? createdAt,
    BackupStatus? status,
    String? filePath,
    String? error,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      if (filePath != null) 'filePath': filePath,
      if (error != null) 'error': error,
    };
  }

  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as String,
      type: BackupType.values.firstWhere(
        (t) => t.name == json['type'] as String,
        orElse: () => BackupType.manual,
      ),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: BackupStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => BackupStatus.pending,
      ),
      filePath: json['filePath'] as String?,
      error: json['error'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BackupRecord) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BackupRecord(id: $id, type: ${type.name}, status: ${status.name})';
}
