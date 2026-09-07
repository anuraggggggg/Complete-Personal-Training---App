package com.cpt.fitness

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val screenSecurityChannelName = "com.myapp.screen_security"
    private var protectionCount = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableProtection()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            screenSecurityChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableProtection" -> {
                    enableProtection()
                    result.success(null)
                }
                "disableProtection" -> {
                    disableProtection()
                    result.success(null)
                }
                "isScreenCaptured" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }

    private fun enableProtection() {
        protectionCount += 1
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun disableProtection() {
        if (protectionCount > 0) {
            protectionCount -= 1
        }
    }

}
