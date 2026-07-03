package com.clickerpro.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * CLICKER PRO home-screen widget.
 *
 * The Flutter side writes a JSON snapshot (today's event count, due amount,
 * next event) into SharedPreferences via the shared_preferences plugin,
 * which stores values in the "FlutterSharedPreferences" file under a
 * "flutter." key prefix. This provider just renders that snapshot — no
 * network, no database. The app broadcasts ACTION_APPWIDGET_UPDATE through
 * a MethodChannel whenever the dashboard recomputes, and the OS refreshes
 * every 30 minutes on its own.
 */
class ClickerProWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    companion object {
        private const val PREFS_FILE = "FlutterSharedPreferences"
        private const val DATA_KEY = "flutter.home_widget_data"

        fun buildViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.clicker_widget)

            val raw = context
                .getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                .getString(DATA_KEY, null)

            var todayCount = 0
            var due = 0.0
            var nextTitle: String? = null
            var nextTime: String? = null
            if (raw != null) {
                try {
                    val json = JSONObject(raw)
                    todayCount = json.optInt("todayEventsCount", 0)
                    due = json.optDouble("dueAmount", 0.0)
                    nextTitle = json.optString("nextEventTitle").ifEmpty { null }
                    nextTime = json.optString("nextEventTime").ifEmpty { null }
                } catch (_: Exception) {
                    // Corrupt snapshot — render the empty state.
                }
            }

            views.setTextViewText(
                R.id.widget_next_title,
                nextTitle ?: "No upcoming event",
            )
            views.setTextViewText(R.id.widget_next_time, nextTime ?: "")
            views.setTextViewText(
                R.id.widget_today_count,
                "Today: $todayCount ${if (todayCount == 1) "event" else "events"}",
            )
            views.setTextViewText(
                R.id.widget_due,
                if (due > 0.5) "Due ৳${"%,.0f".format(due)}" else "",
            )

            // Tapping anywhere opens the app.
            val launch = Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)

            return views
        }
    }
}
