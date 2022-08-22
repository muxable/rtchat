package com.rtirl.chat

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/audio"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> {
                    val intent = Intent(this, AudioService::class.java)
                    intent.putStringArrayListExtra(
                        "urls",
                        ArrayList(call.argument<List<String>>("urls") ?: listOf())
                    )
                    intent.action = AudioService.ACTION_START_SERVICE
                    startService(intent)

                    result.success(true)
                }
                "reload" -> {
                    val intent = Intent(this, AudioService::class.java)
                    intent.action = AudioService.ACTION_START_SERVICE
                    startService(intent)

                    result.success(true)
                }
                "hasPermission" -> {
                    result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                                Settings.canDrawOverlays(this)
                    )
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !Settings.canDrawOverlays(this)
                    ) {
                        startActivityForResult(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ), 8675309
                        )
                    }
                    result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                                Settings.canDrawOverlays(this)
                    )
                }
                else -> result.notImplemented()
            }
        }

        super.configureFlutterEngine(flutterEngine)
    }
}
