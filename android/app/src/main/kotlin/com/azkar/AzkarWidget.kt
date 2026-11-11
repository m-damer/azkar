package com.azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

/** Home-screen widget: shows the azkar whose time window is open right now. */
class AzkarWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
        scheduleNext(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) refreshAll(context)
    }

    companion object {
        private const val ACTION_TICK = "com.azkar.WIDGET_TICK"
        private const val PREFS = "azkar_widget"

        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString("entries", json).apply()
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, AzkarWidget::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
            scheduleNext(context)
        }

        private fun entries(context: Context): JSONArray {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("entries", "[]") ?: "[]"
            return try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
        }

        /** Calendar.DAY_OF_WEEK (Sun = 1) -> 1 = Monday … 7 = Sunday. */
        private fun weekday(c: Calendar): Int = ((c.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1

        private fun hasDay(days: JSONArray, d: Int): Boolean {
            for (i in 0 until days.length()) if (days.getInt(i) == d) return true
            return false
        }

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.azkar_widget)
            val now = Calendar.getInstance()
            val minute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            val today = weekday(now)
            val yesterday = if (today == 1) 7 else today - 1
            val list = entries(context)
            var title: String? = null
            var text: String? = null
            var bestStart = -1
            for (i in 0 until list.length()) {
                val e = list.getJSONObject(i)
                val from = e.getInt("from")
                val to = e.getInt("to")
                val days = e.getJSONArray("days")
                val crosses = from > to
                val active = if (!crosses) {
                    minute in from until to && hasDay(days, today)
                } else if (minute >= from) {
                    hasDay(days, today)
                } else {
                    minute < to && hasDay(days, yesterday)
                }
                if (active && from > bestStart) {
                    bestStart = from
                    title = e.getString("title")
                    text = e.getString("text")
                }
            }
            val body = text ?: context.getString(R.string.widget_empty)
            views.setTextViewText(R.id.widget_title, title ?: context.getString(R.string.widget_name))
            views.setTextViewText(R.id.widget_text, body)
            val size = when {
                body.length > 260 -> 13f
                body.length > 160 -> 15f
                body.length > 80 -> 18f
                else -> 22f
            }
            views.setTextViewTextSize(R.id.widget_text, android.util.TypedValue.COMPLEX_UNIT_SP, size)
            // Nothing scheduled right now: tapping goes to the screen that picks the azkar.
            val tap = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            if (text == null) tap.putExtra("route", "/settings/widget")
            val open = PendingIntent.getActivity(
                context, if (text == null) 2 else 0, tap,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            return views
        }

        /** Wakes the widget at the next moment any window opens or closes. */
        private fun scheduleNext(context: Context) {
            val list = entries(context)
            val now = Calendar.getInstance()
            val minute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            var next = Int.MAX_VALUE
            for (i in 0 until list.length()) {
                val e = list.getJSONObject(i)
                for (m in intArrayOf(e.getInt("from"), e.getInt("to"))) {
                    val d = if (m > minute) m - minute else m + 1440 - minute
                    if (d < next) next = d
                }
            }
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = PendingIntent.getBroadcast(
                context, 1,
                Intent(context, AzkarWidget::class.java).setAction(ACTION_TICK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            am.cancel(pi)
            if (next == Int.MAX_VALUE) return
            val at = now.timeInMillis - now.get(Calendar.SECOND) * 1000L - now.get(Calendar.MILLISECOND) +
                next * 60_000L
            am.setAndAllowWhileIdle(AlarmManager.RTC, at, pi)
        }
    }
}
