package com.azkar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.azkar/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "sync") {
                    AzkarWidget.save(applicationContext, call.arguments as? String ?: "[]")
                    AzkarWidget.refreshAll(applicationContext)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
