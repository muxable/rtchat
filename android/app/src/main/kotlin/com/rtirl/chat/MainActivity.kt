package com.rtirl.chat

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.speech.tts.TextToSpeech
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        val ttsPlugin = TextToSpeechPlugin(this)
        val ttsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tts_plugin"
        )
        // ttsChannel.setMethodCallHandler(ttsPlugin)
        ttsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")
                    if (!text.isNullOrBlank()) {
                        ttsPlugin.speak(text)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is empty or null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
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


class TextToSpeechPlugin(context: Context) : MethodCallHandler {
    private val context: Context = context
    private val tts: TextToSpeech = TextToSpeech(context) {}

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text")
                if (!text.isNullOrBlank()) {
                    tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Text is empty or null", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun speak(text: String) {
        if (!text.isNullOrBlank()) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        }
    }
}
