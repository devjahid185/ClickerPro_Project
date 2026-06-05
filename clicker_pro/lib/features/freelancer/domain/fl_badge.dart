// lib/features/freelancer/domain/fl_badge.dart
//
// Domain models for Freelancer Badges (FL-11).
//
// Badges are earned based on total events completed and special
// achievements. Each badge has a level, icon, and is shareable.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

enum BadgeLevel {
  bronze(10),
  silver(50),
  gold(100),
  platinum(200);

  const BadgeLevel(this.threshold);
  final int threshold;

  static BadgeLevel fromEvents(int events) {
    if (events >= platinum.threshold) return BadgeLevel.platinum;
    if (events >= gold.threshold) return BadgeLevel.gold;
    if (events >= silver.threshold) return BadgeLevel.silver;
    return BadgeLevel.bronze;
  }

  static BadgeLevel? nextFor(int events) {
    for (final level in BadgeLevel.values) {
      if (events < level.threshold) return level;
    }
    return null;
  }
}

enum SpecialBadgeType {
  firstWedding,
  nightSpecialist,
  teamPlayer,
  earlyBird,
  marathonRunner,
  weekendWarrior,
  perfectAttendance,
  clientFavorite;

  static SpecialBadgeType fromString(String value) {
    for (final type in SpecialBadgeType.values) {
      if (type.name == value) return type;
    }
    return SpecialBadgeType.firstWedding;
  }
}

class FlBadge {
  final String id;
  final String name;
  final BadgeLevel level;
  final String description;
  final DateTime earnedAt;
  final String icon;
  final bool shareable;
  final SpecialBadgeType? specialType;

  const FlBadge({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.earnedAt,
    required this.icon,
    this.shareable = true,
    this.specialType,
  });

  bool get isSpecial => specialType != null;

  factory FlBadge.fromJson(Map<String, dynamic> json) {
    return FlBadge(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      level: BadgeLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => BadgeLevel.bronze,
      ),
      description: (json['description'] ?? '').toString(),
      earnedAt: json['earnedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['earnedAt'] as String),
      icon: (json['icon'] ?? '').toString(),
      shareable: json['shareable'] as bool? ?? true,
      specialType: json['specialType'] != null
          ? SpecialBadgeType.fromString(json['specialType'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'level': level.name,
      'description': description,
      'earnedAt': earnedAt.toIso8601String(),
      'icon': icon,
      'shareable': shareable,
      if (specialType != null) 'specialType': specialType!.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlBadge && id == other.id && level == other.level);

  @override
  int get hashCode => Object.hash(id, level);
}

class FlBadgeSummary {
  final int totalEvents;
  final int yearsActive;
  final int specialAchievements;
  final BadgeLevel currentLevel;
  final List<FlBadge> earnedBadges;
  final List<FlBadge> lockedBadges;

  const FlBadgeSummary({
    required this.totalEvents,
    required this.yearsActive,
    required this.specialAchievements,
    required this.currentLevel,
    required this.earnedBadges,
    required this.lockedBadges,
  });

  int get nextLevelThreshold {
    final next = BadgeLevel.nextFor(totalEvents);
    return next?.threshold ?? currentLevel.threshold;
  }

  double get progressToNext {
    final next = BadgeLevel.nextFor(totalEvents);
    if (next == null) return 1.0;
    final prev = BadgeLevel.values
        .where((l) => l.threshold <= totalEvents)
        .lastOrNull;
    final prevThreshold = prev?.threshold ?? 0;
    final range = next.threshold - prevThreshold;
    if (range <= 0) return 1.0;
    return ((totalEvents - prevThreshold) / range).clamp(0.0, 1.0);
  }

  factory FlBadgeSummary.fromJson(Map<String, dynamic> json) {
    return FlBadgeSummary(
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      yearsActive: (json['yearsActive'] as num?)?.toInt() ?? 0,
      specialAchievements: (json['specialAchievements'] as num?)?.toInt() ?? 0,
      currentLevel: BadgeLevel.fromEvents(
        (json['totalEvents'] as num?)?.toInt() ?? 0,
      ),
      earnedBadges:
          (json['earnedBadges'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlBadge.fromJson)
              .toList(growable: false) ??
          const <FlBadge>[],
      lockedBadges:
          (json['lockedBadges'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlBadge.fromJson)
              .toList(growable: false) ??
          const <FlBadge>[],
    );
  }
}
