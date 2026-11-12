package com.azkar

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingRoute = intent?.getStringExtra("route")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val route = intent.getStringExtra("route") ?: return
        val ch = channel
        if (ch != null) ch.invokeMethod("route", route) else pendingRoute = route
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.azkar/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(
                        UpdateDownloader.status(
                            applicationContext,
                            call.argument<String>("url") ?: "",
                            call.argument<Int>("build") ?: 0))
                    "install" -> result.success(UpdateDownloader.install(applicationContext))
                    else -> result.notImplemented()
                }
            }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.azkar/widget")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> {
                    AzkarWidget.save(applicationContext, call.arguments as? String ?: "[]")
                    AzkarWidget.refreshAll(applicationContext)
                    result.success(true)
                }
                "initialRoute" -> {
                    val r = pendingRoute
                    pendingRoute = null
                    result.success(r)
                }
                else -> result.notImplemented()
            }
        }
    }
}
