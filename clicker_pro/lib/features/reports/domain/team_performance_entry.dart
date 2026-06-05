// lib/features/reports/domain/team_performance_entry.dart
//
// Per-team-member performance record returned by
// `GET /api/reports/team-performance?year=YYYY`।
//
// Backend computes `performanceScore = events*10 - reedits*5`, sorted
// descending so the leaderboard has the strongest performer first।

class TeamPerformanceEntry {
  final String userId;
  final String name;

  /// Wire format role string ('OWNER' | 'FREELANCER' | 'BOTH' |
  /// 'MANAGER').  We keep it as the raw string so badge rendering can
  /// route through the existing role-aware helpers without coupling
  /// this DTO to the auth domain enum।
  final String role;

  final int totalEvents;
  final double totalEarnings;
  final int pendingReEdits;
  final int performanceScore;

  const TeamPerformanceEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.totalEvents,
    required this.totalEarnings,
    required this.pendingReEdits,
    required this.performanceScore,
  });

  factory TeamPerformanceEntry.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceEntry(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      totalEvents: _readInt(json['totalEvents']),
      totalEarnings: _readDouble(json['totalEarnings']),
      pendingReEdits: _readInt(json['pendingReEdits']),
      performanceScore: _readInt(json['performanceScore']),
    );
  }

  static int _readInt(Object? raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static double _readDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TeamPerformanceEntry) return false;
    return userId == other.userId &&
        name == other.name &&
        role == other.role &&
        totalEvents == other.totalEvents &&
        totalEarnings == other.totalEarnings &&
        pendingReEdits == other.pendingReEdits &&
        performanceScore == other.performanceScore;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    name,
    role,
    totalEvents,
    totalEarnings,
    pendingReEdits,
    performanceScore,
  );
}
