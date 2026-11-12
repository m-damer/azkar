package com.azkar

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.app.Notification
import java.io.File

/**
 * Downloads the update APK with Android's DownloadManager, so the download
 * keeps going when the app is closed. When it finishes, a notification asks
 * for one tap to install.
 */
object UpdateDownloader {
    private const val PREFS = "azkar_update"
    private const val CHANNEL = "update"
    private const val NOTIF_ID = 7301
    private const val FILE = "azkar-update.apk"

    private fun dm(c: Context) = c.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Starts a download for [build], or reports the one already there. */
    fun status(c: Context, url: String, build: Int): Map<String, Any> {
        val p = prefs(c)
        val id = p.getLong("id", -1L)
        if (id >= 0 && p.getInt("build", -1) == build) {
            val s = query(c, id)
            if (s != null) return s
        }
        if (id >= 0) dm(c).remove(id)
        val file = File(c.getExternalFilesDir(null), FILE)
        if (file.exists()) file.delete()
        val req = DownloadManager.Request(Uri.parse(url))
            .setTitle("تحديث أذكار")
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(c, null, FILE)
        val newId = dm(c).enqueue(req)
        p.edit().putLong("id", newId).putInt("build", build).apply()
        return query(c, newId) ?: mapOf("state" to "running", "progress" to 0.0)
    }

    /** null when the system no longer knows the download. */
    private fun query(c: Context, id: Long): Map<String, Any>? {
        dm(c).query(DownloadManager.Query().setFilterById(id))?.use { cur ->
            if (!cur.moveToFirst()) return null
            val st = cur.getInt(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val got = cur.getLong(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = cur.getLong(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            val progress = if (total > 0) got.toDouble() / total else 0.0
            return when (st) {
                DownloadManager.STATUS_SUCCESSFUL -> mapOf("state" to "done", "progress" to 1.0)
                DownloadManager.STATUS_FAILED -> null
                else -> mapOf("state" to "running", "progress" to progress)
            }
        }
        return null
    }

    /** Opens the system installer for the saved download. */
    fun install(c: Context): Boolean {
        val id = prefs(c).getLong("id", -1L)
        if (id < 0) return false
        val uri = dm(c).getUriForDownloadedFile(id) ?: return false
        (c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTIF_ID)
        val i = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return try { c.startActivity(i); true } catch (_: Exception) { false }
    }

    fun onComplete(c: Context, doneId: Long) {
        val p = prefs(c)
        if (doneId != p.getLong("id", -1L)) return
        if (query(c, doneId)?.get("state") != "done") return
        val nm = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "التحديثات", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val tap = PendingIntent.getBroadcast(
            c, 0, Intent(c, UpdateInstallReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, CHANNEL) else Notification.Builder(c)
        val n = b
            .setSmallIcon(c.applicationInfo.icon)
            .setContentTitle("اكتمل تنزيل التحديث")
            .setContentText("اضغط لتثبيت النسخة الجديدة من أذكار")
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        nm.notify(NOTIF_ID, n)
    }
}

class UpdateDoneReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        UpdateDownloader.onComplete(context, intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L))
    }
}

/** The notification tap: opens the installer. */
class UpdateInstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        UpdateDownloader.install(context)
    }
}
