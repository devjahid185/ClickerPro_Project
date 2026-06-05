import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/widget_data.dart';

const String _kWidgetDataKey = 'home_widget_data';
const String _kShowEventsCountKey = 'widget_show_events_count';
const String _kShowDueAmountKey = 'widget_show_due_amount';
const String _kShowNextEventKey = 'widget_show_next_event';
const String _kRefreshIntervalKey = 'widget_refresh_interval';

enum WidgetRefreshInterval {
  thirtyMinutes(30),
  oneHour(60),
  manual(-1);

  const WidgetRefreshInterval(this.minutes);
  final int minutes;
}

class WidgetService {
  WidgetService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> updateWidget(WidgetData data) async {
    final json = jsonEncode(data.toJson());
    await _prefs.setString(_kWidgetDataKey, json);
  }

  WidgetData getWidgetData() {
    final raw = _prefs.getString(_kWidgetDataKey);
    if (raw == null) return WidgetData.empty();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return WidgetData.fromJson(decoded);
    } catch (_) {
      return WidgetData.empty();
    }
  }

  bool get showEventsCount => _prefs.getBool(_kShowEventsCountKey) ?? true;
  bool get showDueAmount => _prefs.getBool(_kShowDueAmountKey) ?? true;
  bool get showNextEvent => _prefs.getBool(_kShowNextEventKey) ?? true;

  Future<void> setShowEventsCount(bool value) =>
      _prefs.setBool(_kShowEventsCountKey, value);
  Future<void> setShowDueAmount(bool value) =>
      _prefs.setBool(_kShowDueAmountKey, value);
  Future<void> setShowNextEvent(bool value) =>
      _prefs.setBool(_kShowNextEventKey, value);

  WidgetRefreshInterval get refreshInterval {
    final raw = _prefs.getString(_kRefreshIntervalKey);
    if (raw == null) return WidgetRefreshInterval.thirtyMinutes;
    return WidgetRefreshInterval.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => WidgetRefreshInterval.thirtyMinutes,
    );
  }

  Future<void> setRefreshInterval(WidgetRefreshInterval interval) =>
      _prefs.setString(_kRefreshIntervalKey, interval.name);
}
