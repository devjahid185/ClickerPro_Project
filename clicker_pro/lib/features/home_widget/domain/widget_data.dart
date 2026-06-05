class WidgetData {
  const WidgetData({
    this.todayEventsCount = 0,
    this.dueAmount = 0,
    this.nextEventTitle,
    this.nextEventTime,
    this.lastUpdated,
  });

  final int todayEventsCount;
  final double dueAmount;
  final String? nextEventTitle;
  final String? nextEventTime;
  final DateTime? lastUpdated;

  factory WidgetData.empty() => const WidgetData();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'todayEventsCount': todayEventsCount,
      'dueAmount': dueAmount,
      'nextEventTitle': nextEventTitle,
      'nextEventTime': nextEventTime,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      todayEventsCount: (json['todayEventsCount'] as num?)?.toInt() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      nextEventTitle: json['nextEventTitle'] as String?,
      nextEventTime: json['nextEventTime'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  WidgetData copyWith({
    int? todayEventsCount,
    double? dueAmount,
    String? nextEventTitle,
    String? nextEventTime,
    DateTime? lastUpdated,
  }) {
    return WidgetData(
      todayEventsCount: todayEventsCount ?? this.todayEventsCount,
      dueAmount: dueAmount ?? this.dueAmount,
      nextEventTitle: nextEventTitle ?? this.nextEventTitle,
      nextEventTime: nextEventTime ?? this.nextEventTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WidgetData) return false;
    return todayEventsCount == other.todayEventsCount &&
        dueAmount == other.dueAmount &&
        nextEventTitle == other.nextEventTitle &&
        nextEventTime == other.nextEventTime;
  }

  @override
  int get hashCode =>
      Object.hash(todayEventsCount, dueAmount, nextEventTitle, nextEventTime);

  @override
  String toString() =>
      'WidgetData(events: $todayEventsCount, due: $dueAmount, '
      'next: $nextEventTitle @ $nextEventTime)';
}
