enum ExportType { csv, googleSheets, pdf, zip }

enum ExportScope { bookings, clients, payments, expenses, all }

class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange({required this.from, required this.to});

  factory DateRange.today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateRange(from: today, to: today.add(const Duration(days: 1)));
  }

  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    return DateRange(from: start, to: start.add(const Duration(days: 7)));
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    return DateRange(from: start, to: end);
  }

  static DateRange all() {
    return DateRange(
      from: DateTime(2020),
      to: DateTime.now().add(const Duration(days: 1)),
    );
  }
}

class ExportConfig {
  final ExportType type;
  final Set<ExportScope> scopes;
  final DateRange dateRange;

  const ExportConfig({
    required this.type,
    required this.scopes,
    required this.dateRange,
  });

  ExportConfig copyWith({
    ExportType? type,
    Set<ExportScope>? scopes,
    DateRange? dateRange,
  }) {
    return ExportConfig(
      type: type ?? this.type,
      scopes: scopes ?? this.scopes,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}
