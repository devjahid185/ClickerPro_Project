// lib/features/bookings/domain/event_type_vibe.dart
//
// Presentation "vibe" for each EventType — a label, an icon and an accent
// colour — so occasions read distinctly across the app (dashboard header chip,
// booking cards, etc.). Kept separate from the pure-Dart EventType enum so the
// domain stays Flutter-free.

import 'package:flutter/material.dart';

import 'event_type.dart';

/// Visual identity for an occasion / event type.
class EventVibe {
  const EventVibe({
    required this.label,
    required this.icon,
    required this.color,
    required this.emoji,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String emoji;
}

extension EventTypeVibe on EventType {
  /// The display vibe (label + icon + accent + emoji) for this occasion.
  EventVibe get vibe {
    switch (this) {
      case EventType.wedding:
        return const EventVibe(
          label: 'Wedding',
          icon: Icons.favorite_rounded,
          color: Color(0xFFE5397A), // rose
          emoji: '💍',
        );
      case EventType.holud:
        return const EventVibe(
          label: 'Holud',
          icon: Icons.local_florist_rounded,
          color: Color(0xFFE6A800), // turmeric gold
          emoji: '🌼',
        );
      case EventType.birthday:
        return const EventVibe(
          label: 'Birthday',
          icon: Icons.cake_rounded,
          color: Color(0xFF7C5CFF), // violet
          emoji: '🎂',
        );
      case EventType.corporate:
        return const EventVibe(
          label: 'Corporate',
          icon: Icons.business_center_rounded,
          color: Color(0xFF2E7DD6), // corporate blue
          emoji: '🏢',
        );
      case EventType.preWedding:
        return const EventVibe(
          label: 'Pre-Wedding',
          icon: Icons.photo_camera_front_rounded,
          color: Color(0xFFFF6200), // signal orange
          emoji: '📸',
        );
      case EventType.anniversary:
        return const EventVibe(
          label: 'Anniversary',
          icon: Icons.celebration_rounded,
          color: Color(0xFFD64550), // ruby
          emoji: '🥂',
        );
      case EventType.outdoor:
        return const EventVibe(
          label: 'Outdoor',
          icon: Icons.landscape_rounded,
          color: Color(0xFF2E9E5B), // green
          emoji: '🏞️',
        );
      case EventType.other:
        return const EventVibe(
          label: 'Event',
          icon: Icons.event_rounded,
          color: Color(0xFF6B7280), // slate
          emoji: '🎈',
        );
    }
  }
}
