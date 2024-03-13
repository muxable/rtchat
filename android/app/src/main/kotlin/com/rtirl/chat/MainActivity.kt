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

        notificationChannel.setMethodCallHandler { call, result ->

            Log.d("NotificationService", "startForeground called");

            Log.d("Notification called", call.method);

           when(call.method) {
               "dismissNotification" -> {
                   val notificationId = NOTIFICATION_ID
                   val intent = Intent(this, NotificationService::class.java)
                   intent.putExtra("action", "dismissNotification")
                   intent.putExtra("id", notificationId)
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
    private val tts: TextToSpeech = TextToSpeechSingleton.getInstance(context)


    companion object {
        private const val CHANNEL_ID = "tts_channel"
        private const val NOTIFICATION_ID = 6853027
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        Log.d("TextToSpeechPlugin", call.method)

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
            "disableTTS" -> {
                dismissTTSNotification(result)
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
                    showTTSNotification()
                }

                override fun onDone(utteranceId: String) {
                    result.success(true)
                    dismissTTSNotification(result)
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
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, params)
        }
    }

    private fun showTTSNotification() {
        Log.d("NotificationService", "showNotification called")
        val intent = Intent(context, NotificationService::class.java)
        intent.putExtra("action", "showNotification")
        context.startService(intent)
    }


    private fun dismissTTSNotification(result: Result) {
                   val notificationId = NOTIFICATION_ID
                   val intent = Intent(context, NotificationService::class.java)
                   intent.putExtra("action", "dismissNotification")
                   intent.putExtra("id", notificationId)
                   context.startService(intent)
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