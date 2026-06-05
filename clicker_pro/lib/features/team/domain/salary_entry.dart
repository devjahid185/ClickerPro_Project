// lib/features/team/domain/salary_entry.dart
//
// Domain model for Team Salary Sheet (MOD-58).
//
// Tracks per-member earnings based on events worked, rate per event,
// amounts paid, and outstanding balances.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

class SalaryEntry {
  final String memberId;
  final String memberName;
  final int eventsCount;
  final double ratePerEvent;
  final double totalEarned;
  final double totalPaid;
  final double totalDue;

  const SalaryEntry({
    required this.memberId,
    required this.memberName,
    required this.eventsCount,
    required this.ratePerEvent,
    required this.totalEarned,
    required this.totalPaid,
    required this.totalDue,
  });

  double get pendingAmount => totalEarned - totalPaid;

  bool get isFullyPaid => pendingAmount <= 0;

  SalaryEntry copyWith({
    String? memberId,
    String? memberName,
    int? eventsCount,
    double? ratePerEvent,
    double? totalEarned,
    double? totalPaid,
    double? totalDue,
  }) {
    return SalaryEntry(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      eventsCount: eventsCount ?? this.eventsCount,
      ratePerEvent: ratePerEvent ?? this.ratePerEvent,
      totalEarned: totalEarned ?? this.totalEarned,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDue: totalDue ?? this.totalDue,
    );
  }

  factory SalaryEntry.fromJson(Map<String, dynamic> json) {
    return SalaryEntry(
      memberId: (json['memberId'] ?? '').toString(),
      memberName: (json['memberName'] ?? '').toString(),
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      ratePerEvent: (json['ratePerEvent'] as num?)?.toDouble() ?? 0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'memberId': memberId,
      'memberName': memberName,
      'eventsCount': eventsCount,
      'ratePerEvent': ratePerEvent,
      'totalEarned': totalEarned,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryEntry &&
          memberId == other.memberId &&
          totalEarned == other.totalEarned &&
          totalPaid == other.totalPaid);

  @override
  int get hashCode => Object.hash(memberId, totalEarned, totalPaid);

  @override
  String toString() =>
      'SalaryEntry(member: $memberName, events: $eventsCount, '
      'earned: $totalEarned, paid: $totalPaid, due: $totalDue)';
}

class SalarySheet {
  final String month;
  final int totalEvents;
  final double totalEarned;
  final double totalPaid;
  final double totalDue;
  final List<SalaryEntry> entries;

  const SalarySheet({
    required this.month,
    required this.totalEvents,
    required this.totalEarned,
    required this.totalPaid,
    required this.totalDue,
    required this.entries,
  });

  bool get hasOutstanding => totalDue > 0;

  factory SalarySheet.empty(String month) {
    return SalarySheet(
      month: month,
      totalEvents: 0,
      totalEarned: 0,
      totalPaid: 0,
      totalDue: 0,
      entries: const <SalaryEntry>[],
    );
  }

  factory SalarySheet.fromJson(Map<String, dynamic> json) {
    return SalarySheet(
      month: (json['month'] ?? '').toString(),
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
      entries:
          (json['entries'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(SalaryEntry.fromJson)
              .toList(growable: false) ??
          const <SalaryEntry>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'month': month,
      'totalEvents': totalEvents,
      'totalEarned': totalEarned,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
  }
}
