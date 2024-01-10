package com.rtirl.chat

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID
import android.os.Bundle


class MainActivity : FlutterActivity() {

    private var sharedData: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
         handleIntent()
    }
  


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        val ttsPlugin = TextToSpeechPlugin(this)
        val ttsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tts_plugin"
        )
        ttsChannel.setMethodCallHandler(ttsPlugin)
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/share"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getSharedData") {
                result.success(sharedData)
                sharedData = ""
            }
        }

        super.configureFlutterEngine(flutterEngine)
    }

    private fun handleIntent() {
        // Handle the received text share intent
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            intent.getStringExtra(Intent.EXTRA_TEXT)?.let { intentData ->
                sharedData = intentData
            }
        }
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
                    speak(text, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Text is empty or null", null)
                }
            }
            "getLanguages" -> {
                val languageMap = getLanguages()
                result.success(languageMap)
            }
            "stopSpeaking" -> {
                stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    fun speak(text: String, result: Result) {
        if (!text.isNullOrBlank()) {
            val utteranceId = UUID.randomUUID().toString()
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String) {
                    // Speech has started
                }

                override fun onDone(utteranceId: String) {
                    result.success(true)
                }

                override fun onError(utteranceId: String) {
                    // Speech encountered an error
                    // Handle errors as needed
                }
            })

            // Speak with the specified utteranceId
            val params = HashMap<String, String>()
            params[TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID] = utteranceId
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, params)
        }
    }

    fun getLanguages(): Map<String, String> {
        val languageMap = mutableMapOf<String, String>()
        val locales = tts.availableLanguages
        for (locale in locales) {
            val languageCode = locale.language
            val languageName = locale.displayName
            languageMap[languageCode] = languageName
        }
        return languageMap
    }

    fun stop() {
        if (tts.isSpeaking) {
            tts.stop()
        }
    }
}
