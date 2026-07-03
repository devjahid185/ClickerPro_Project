// lib/features/home_widget/data/widget_refresher.dart
//
// Feeds the native Android home widget. The dashboard calls
// [WidgetRefresher.push] whenever its metrics recompute: the snapshot is
// written to shared_preferences (which the Kotlin AppWidgetProvider reads
// from FlutterSharedPreferences directly) and the "clickerpro/widget"
// MethodChannel pokes the provider so the widget redraws immediately.
//
// Fail-soft everywhere: a widget problem must never affect the app. On
// web/desktop/iOS the channel simply isn't implemented and the poke is a
// silent no-op.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/widget_data.dart';
import 'widget_service.dart';

class WidgetRefresher {
  WidgetRefresher._();

  static const MethodChannel _channel = MethodChannel('clickerpro/widget');

  /// The last snapshot pushed this session — skips redundant writes when the
  /// dashboard rebuilds without the numbers changing.
  static WidgetData? _last;

  static Future<void> push(WidgetData data) async {
    if (kIsWeb) return;
    if (_last == data) return;
    _last = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await WidgetService(prefs)
          .updateWidget(data.copyWith(lastUpdated: DateTime.now()));
      await _channel.invokeMethod<bool>('refreshWidget');
    } on MissingPluginException {
      // Not Android (or engine not ready) — the snapshot is still saved.
    } catch (e) {
      AppLogger.w('widget', 'refresh failed: $e');
    }
  }
}
