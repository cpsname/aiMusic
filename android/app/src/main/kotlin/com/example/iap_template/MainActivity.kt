package com.example.iap_template

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // infra_core/DeviceBootClock: reports the device boot instant for reboot
        // detection (epoch millis = now - uptime).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "infra_core/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "getBootTimeMillis") {
                    result.success(System.currentTimeMillis() - SystemClock.elapsedRealtime())
                } else {
                    result.notImplemented()
                }
            }
    }
}
