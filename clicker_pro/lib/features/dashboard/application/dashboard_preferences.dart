// lib/features/dashboard/application/dashboard_preferences.dart
//
// Clicker Pro — Dashboard section preferences (MOD-62)
//
// Persists section order + visibility via SharedPreferences.
// Riverpod StateNotifier exposes the state as an immutable list.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/dashboard_section.dart';

const String _kDashSectionsKey = 'dashboard_sections_v1';

// One-time migration flag. Existing installs persisted the Weather section
// as enabled, so a plain default change wouldn't reach them — their old
// prefs still show the (fake) weather card. On first load after this
// update we force Weather off once; afterwards the user's own choice wins.
const String _kWeatherMigratedKey = 'dashboard_weather_hidden_v1';

class DashboardPrefsNotifier extends StateNotifier<List<DashboardSection>> {
  DashboardPrefsNotifier() : super(DashboardSection.defaultOrder) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDashSectionsKey);
    if (raw == null) {
      state = DashboardSection.defaultOrder;
      return;
    }
    try {
      var list = (jsonDecode(raw) as List<dynamic>)
          .map(
            (e) => DashboardSection(
              type: DashboardSectionType.values[e['type'] as int],
              label: e['label'] as String,
              enabled: e['enabled'] as bool,
              order: e['order'] as int,
            ),
          )
          .toList();
      if (list.length == DashboardSectionType.values.length) {
        // One-time: hide the (fake) weather card on existing installs.
        if (!(prefs.getBool(_kWeatherMigratedKey) ?? false)) {
          list = [
            for (final s in list)
              if (s.type == DashboardSectionType.weather)
                s.copyWith(enabled: false)
              else
                s,
          ];
          await prefs.setBool(_kWeatherMigratedKey, true);
          state = list;
          await _save();
          return;
        }
        state = list;
      }
    } catch (_) {
      state = DashboardSection.defaultOrder;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      state
          .map(
            (s) => {
              'type': s.type.index,
              'label': s.label,
              'enabled': s.enabled,
              'order': s.order,
            },
          )
          .toList(),
    );
    await prefs.setString(_kDashSectionsKey, encoded);
  }

  void reorderSection(int oldIndex, int newIndex) {
    final items = List<DashboardSection>.from(state);
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
    _save();
  }

  void toggleSection(DashboardSectionType type, bool enabled) {
    state = [
      for (final s in state)
        if (s.type == type) s.copyWith(enabled: enabled) else s,
    ];
    _save();
  }

  void resetToDefault() {
    state = DashboardSection.defaultOrder;
    _save();
  }
}

final dashboardPrefsProvider =
    StateNotifierProvider<DashboardPrefsNotifier, List<DashboardSection>>(
      (ref) => DashboardPrefsNotifier(),
    );
