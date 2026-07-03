package com.clickerpro.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Dart pokes this after writing a fresh widget snapshot to
        // SharedPreferences so the home widget redraws immediately instead
        // of waiting for the 30-minute platform cycle.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "clickerpro/widget",
        ).setMethodCallHandler { call, result ->
            if (call.method == "refreshWidget") {
                val manager = AppWidgetManager.getInstance(this)
                val ids = manager.getAppWidgetIds(
                    ComponentName(this, ClickerProWidgetProvider::class.java),
                )
                for (id in ids) {
                    manager.updateAppWidget(
                        id,
                        ClickerProWidgetProvider.buildViews(this),
                    )
                }
                result.success(ids.isNotEmpty())
            } else {
                result.notImplemented()
            }
        }
    }
}
