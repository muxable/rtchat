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
import android.app.NotificationChannel
import android.app.NotificationManager
import android.util.Log
import androidx.core.app.NotificationCompat


class MainActivity : FlutterActivity() {

    private var sharedData: String = ""

    companion object {

        var methodChannel: MethodChannel? = null

        const val NOTIFICATION_ID = 6853027
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent()
        startNotificationService()
    }

    private fun startNotificationService() {
        val intent = Intent(this, NotificationService::class.java)
        startService(intent)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        val ttsPlugin = TextToSpeechPlugin(this)
        val ttsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ttsPlugin"
        )

        val notificationChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "tts_notifications"
        )

        methodChannel = notificationChannel

        notificationChannel.setMethodCallHandler { call, result ->

            Log.d("NotificationService", "startForeground called");

            Log.d("Notification called", call.method);

           when(call.method) {
               "dismissNotification" -> {
                   val intent = Intent(this, NotificationService::class.java)
                   intent.putExtra("action", "dismissNotification")
                   intent.putExtra("id", NOTIFICATION_ID)
                   startService(intent)
                   result.success(true)
               }
               "showNotification" -> {
                   val intent = Intent(this, NotificationService::class.java)
                   intent.putExtra("action", "showNotification")
                   startService(intent)
                   result.success(true)
               }
               else -> result.notImplemented()
           }
        }

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

    companion object {
        private const val NOTIFICATION_ID = 6853027
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        Log.d("TextToSpeechPlugin", call.method)

        when (call.method) {
            "updateTTSPreferences" -> {
                val pitch = call.argument<Double?>("pitch")
                val speed = call.argument<Double?>("speed")
                if (pitch != null && speed != null) {
                    updateTTSPreferences(pitch.toFloat(), speed.toFloat())
                }
            }
            "speak" -> {
                val text = call.argument<String>("text")
                val speed = call.argument<Double?>("speed")
                val volume = call.argument<Double?>("volume")
                if (!text.isNullOrBlank()) {
                    speak(text, speed?.toFloat(), volume?.toFloat(), result)
                } else {
                    result.error("INVALID_ARGUMENT", "Text is empty or null", null)
                }
            }
            "getLanguages" -> {
                val languageMap = getLanguages()
                result.success(languageMap)
            }
            "disableTTS" -> {
                dismissTTSNotification(result)
            }
            "stopSpeaking" -> {
                stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    fun updateTTSPreferences(pitch: Float, speed: Float) {
        tts.setPitch(pitch)
        tts.setSpeechRate(speed)
    }

    fun speak(text: String, speed: Float?, volume: Float?, result: Result) {
        if (!text.isNullOrBlank()) {
            val utteranceId = UUID.randomUUID().toString()
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String) {
                   
                }

                override fun onDone(utteranceId: String) {
                    result.success(true)
                }

                override fun onError(utteranceId: String) {
                    // Speech encountered an error
                    // Handle errors as needed
                    dismissTTSNotification(result)
                }
            })

            // Speak with the specified utteranceId
            val params = HashMap<String, String>()
            params[TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID] = utteranceId
            if (speed != null) {
                tts.setSpeechRate(speed)
            }
            if (volume != null) {
                tts.setVolume(volume)
            }
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, params)
        }
    }

    private fun dismissTTSNotification(result: Result) {
        val notificationId = NOTIFICATION_ID
        val intent = Intent(context, NotificationService::class.java)
        intent.putExtra("action", "dismissNotification")
        intent.putExtra("id", notificationId)
        context.startService(intent)
        stop()
        result.success(true)
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
            Log.d("TTS", "Stopped speaking")
        }
    }
}
