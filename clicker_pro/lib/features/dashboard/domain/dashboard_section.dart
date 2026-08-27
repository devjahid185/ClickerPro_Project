// lib/features/dashboard/domain/dashboard_section.dart
//
// Graphy7 — Dashboard section model (MOD-62)
//
// Defines every section type that can appear on the dashboard, plus
// the user's preferred ordering and visibility. Default order follows
// the spec layout exactly.

enum DashboardSectionType {
  weekStrip,
  splitHero,
  deliveredBar,
  quickActions,
  announcement,
  financeRow,
  holidays,
  weather,
}

class DashboardSection {
  const DashboardSection({
    required this.type,
    required this.label,
    required this.enabled,
    required this.order,
  });

  final DashboardSectionType type;
  final String label;
  final bool enabled;
  final int order;

  DashboardSection copyWith({bool? enabled, int? order}) {
    return DashboardSection(
      type: type,
      label: label,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  /// Spec order — all enabled, ordered as listed.
  static const List<DashboardSection> defaultOrder = [
    DashboardSection(
      type: DashboardSectionType.weekStrip,
      label: 'Week Strip',
      enabled: true,
      order: 0,
    ),
    DashboardSection(
      type: DashboardSectionType.splitHero,
      label: 'Today & Upcoming',
      enabled: true,
      order: 1,
    ),
    DashboardSection(
      type: DashboardSectionType.deliveredBar,
      label: 'Complete',
      enabled: true,
      order: 2,
    ),
    DashboardSection(
      type: DashboardSectionType.quickActions,
      label: 'Quick Actions',
      enabled: true,
      order: 3,
    ),
    DashboardSection(
      type: DashboardSectionType.announcement,
      label: 'Announcements',
      enabled: true,
      order: 4,
    ),
    DashboardSection(
      type: DashboardSectionType.financeRow,
      label: 'Finance',
      enabled: true,
      order: 5,
    ),
    DashboardSection(
      type: DashboardSectionType.holidays,
      label: 'Holidays & Cancelled',
      enabled: true,
      order: 6,
    ),
    DashboardSection(
      type: DashboardSectionType.weather,
      label: 'Weather',
      enabled: true,
      order: 7,
    ),
  ];
}
