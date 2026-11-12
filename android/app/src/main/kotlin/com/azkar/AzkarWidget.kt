package com.azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
import android.widget.RemoteViews
import android.os.Build
import org.json.JSONArray
import java.util.Calendar

/** Home-screen widget: shows the azkar whose time window is open right now. */
class AzkarWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context, manager, id))
        scheduleNext(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle
    ) {
        manager.updateAppWidget(id, build(context, manager, id))
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

        /** Font scale of the title and the text (1 = the default size). */
        fun saveStyle(context: Context, title: Float, text: Float) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putFloat("titleScale", title).putFloat("textScale", text).apply()
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, AzkarWidget::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context, manager, id))
            scheduleNext(context)
        }

        private fun entries(context: Context): JSONArray {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("entries", "[]") ?: "[]"
            return try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
        }

        /** Calendar.DAY_OF_WEEK (Sun = 1) -> 1 = Monday … 7 = Sunday. */
        private fun weekday(c: Calendar): Int = ((c.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1

        /** The azkar of a list; an old single-azkar entry counts as a list of one. */
        private fun itemsOf(e: org.json.JSONObject): JSONArray {
            val arr = e.optJSONArray("items")
            if (arr != null) return arr
            val one = JSONArray()
            if (e.has("text")) {
                one.put(org.json.JSONObject().put("title", e.optString("title")).put("text", e.getString("text")))
            }
            return one
        }

        private fun hasDay(days: JSONArray, d: Int): Boolean {
            for (i in 0 until days.length()) if (days.getInt(i) == d) return true
            return false
        }

        private fun font(context: Context, res: Int): Typeface =
            if (Build.VERSION.SDK_INT >= 26) {
                try { context.resources.getFont(res) } catch (e: Exception) { Typeface.DEFAULT }
            } else Typeface.DEFAULT

        /**
         * The launcher may ignore font resources inside a widget, so the text is drawn here with
         * the app's own fonts and shown as an image. It is white on transparent; the ImageView's
         * tint (a day / night colour) gives it its colour.
         */
        private fun render(
            context: Context, text: String, face: Typeface, widthDp: Float, heightDp: Float,
            maxSp: Float, minSp: Float, center: Boolean, maxLines: Int
        ): Bitmap {
            val d = context.resources.displayMetrics.density
            val w = maxOf(1, (widthDp * d).toInt())
            val h = maxOf(1, (heightDp * d).toInt())
            val paint = TextPaint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                typeface = face
                color = Color.WHITE
            }
            val align = if (center) Layout.Alignment.ALIGN_CENTER else Layout.Alignment.ALIGN_NORMAL
            fun layout(sp: Float): StaticLayout {
                paint.textSize = sp * d
                val b = StaticLayout.Builder.obtain(text, 0, text.length, paint, w)
                    .setAlignment(align)
                    .setTextDirection(TextDirectionHeuristics.RTL)
                    .setLineSpacing(0f, 1.15f)
                    .setIncludePad(false)
                if (maxLines == 1) b.setMaxLines(1).setEllipsize(TextUtils.TruncateAt.END)
                return b.build()
            }
            var sp = maxSp
            var l = layout(sp)
            while (sp > minSp && (l.height > h || (maxLines == 1 && paint.measureText(text) > w))) {
                sp -= 1f
                l = layout(sp)
            }
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val c = Canvas(bmp)
            c.translate(0f, maxOf(0f, (h - l.height) / 2f))
            l.draw(c)
            return bmp
        }

        private fun build(context: Context, manager: AppWidgetManager, id: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.azkar_widget)
            val now = Calendar.getInstance()
            val minute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            val today = weekday(now)
            val yesterday = if (today == 1) 7 else today - 1
            val list = entries(context)
            var title: String? = null
            var text: String? = null
            var bestStart = -1
            var bestRank = -1L
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
                val rank = e.optLong("rank", 0L)
                if (active && (from > bestStart || (from == bestStart && rank > bestRank))) {
                    bestStart = from
                    bestRank = rank
                    val items = itemsOf(e)
                    if (items.length() > 0) {
                        // Which azkar of the list is on now: one every `minutes`, round and round.
                        val elapsed = if (minute >= from) minute - from else minute + 1440 - from
                        val step = maxOf(1, e.optInt("minutes", 5))
                        val cur = items.getJSONObject((elapsed / step) % items.length())
                        title = cur.getString("title")
                        text = cur.getString("text")
                    }
                }
            }
            val body = text ?: context.getString(R.string.widget_empty)
            val label = title ?: context.getString(R.string.widget_name)
            val opts = manager.getAppWidgetOptions(id)
            val wDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
                .let { if (it > 0) it else 250 } - 32f
            val hDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                .let { if (it > 0) it else 110 } - 32f - 18f - 6f
            val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val titleScale = sp.getFloat("titleScale", 1f).coerceIn(1f, 5f)
            val textScale = sp.getFloat("textScale", 1f).coerceIn(1f, 5f)
            val areaDp = maxOf(hDp + 18f, 42f) // height left for title + text
            val titleH = maxOf(18f, minOf(Math.ceil((12f * titleScale * 1.5f).toDouble()).toFloat(), areaDp * 0.4f))
            val textH = maxOf(areaDp - titleH, 24f)
            views.setImageViewBitmap(
                R.id.widget_title,
                render(context, label, font(context, R.font.plex_arabic_medium),
                    wDp, titleH, 12f * titleScale, 12f, false, 1)
            )
            views.setImageViewBitmap(
                R.id.widget_text,
                render(context, body, font(context, R.font.amiri_regular),
                    wDp, textH, 17f * textScale, 10f, true, Int.MAX_VALUE)
            )
            views.setContentDescription(R.id.widget_title, label)
            views.setContentDescription(R.id.widget_text, body)
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
                val from = e.getInt("from")
                val to = e.getInt("to")
                val points = ArrayList<Int>()
                points.add(from)
                points.add(to)
                // Inside the window, also wake when the next azkar of the list is due.
                val n = itemsOf(e).length()
                if (n > 1) {
                    val step = maxOf(1, e.optInt("minutes", 5))
                    val len = (to - from + 1440) % 1440
                    var k = step
                    while (k < (if (len == 0) 1440 else len)) {
                        points.add((from + k) % 1440)
                        k += step
                    }
                }
                for (m in points) {
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
