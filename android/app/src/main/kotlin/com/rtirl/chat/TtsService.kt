package com.rtirl.chat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Foreground service that runs while text to speech is on. Without it Android
 * freezes the app shortly after it's backgrounded and mutes its audio, so chat
 * stops being read out mid-stream.
 */
class TtsService : Service() {
    companion object {
        private const val CHANNEL_ID = "tts"
        private const val NOTIFICATION_ID = 6853027
        private const val ACTION_START = "com.rtirl.chat.tts.START"
        private const val ACTION_TURN_OFF = "com.rtirl.chat.tts.TURN_OFF"

        /** Set by MainActivity so the notification can turn tts off in Dart. */
        var channel: MethodChannel? = null

        @Volatile
        var isRunning = false
            private set

        fun start(context: Context, title: String, text: String, turnOff: String) {
            val intent = Intent(context, TtsService::class.java).apply {
                action = ACTION_START
                putExtra("title", title)
                putExtra("text", text)
                putExtra("turnOff", turnOff)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TtsService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_TURN_OFF) {
            channel?.invokeMethod("turnOff", null)
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra("title") ?: "Text to speech"
        val text = intent?.getStringExtra("text") ?: ""
        val turnOff = intent?.getStringExtra("turnOff") ?: "Turn off"
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            buildNotification(title, text, turnOff),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            } else {
                0
            }
        )
        isRunning = true
        // if the app is killed, tts goes with it: don't restart without it.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    private fun buildNotification(title: String, text: String, turnOff: String) =
        NotificationCompat.Builder(this, ensureChannel(title))
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.notification_icon)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(
                PendingIntent.getActivity(
                    this, 0, Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            .addAction(
                R.drawable.text_to_speech, turnOff,
                PendingIntent.getService(
                    this, 1,
                    Intent(this, TtsService::class.java).setAction(ACTION_TURN_OFF),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            .build()

    private fun ensureChannel(name: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW)
            )
        }
        return CHANNEL_ID
    }
}
