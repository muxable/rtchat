package com.rtirl.chat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.rtirl.chat.DisableTTSReceiver
import com.rtirl.chat.R

class NotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "NotificationServiceChannel"
        const val NOTIFICATION_ID = 6853027
        const val CHANNEL_NAME = "Text-to-Speech Notification"
        const val CHANNEL_DESCRIPTION = "Text-to-speech is enabled"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.getStringExtra("action")) {
            "showNotification" -> {
                showNotification()
            }
            "dismissNotification" -> {
                dismissNotification(NOTIFICATION_ID)
            }
            "ttsDisabled" -> {
                notifyFlutterTTSDisabled()
            }
            else -> {
                // If no action specified, start the service in the foreground with a default notification
                showNotification()
            }
        }
        return START_NOT_STICKY
    }

    private fun notifyFlutterTTSDisabled() {
        MainActivity.methodChannel?.invokeMethod("disableTTs", null)
        stopForeground(true)
        stopSelf()
    }

    private fun showNotification() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val disableIntent = Intent(this, DisableTTSReceiver::class.java).apply {
            action = "com.rtirl.chat.ACTION_DISABLE_TTS"
        }
        val disablePendingIntent: PendingIntent =
            PendingIntent.getBroadcast(this, 0, disableIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Text-to-Speech Notification")
            .setContentText("Text-to-speech is enabled")
            .setSmallIcon(R.drawable.notification_icon)
            .addAction(R.drawable.text_to_speech, "Disable TTS", disablePendingIntent)
            .setContentIntent(pendingIntent)
            .setSilent(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun dismissNotification(notificationId: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
        stopForeground(true)
        stopSelf()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = CHANNEL_NAME
            val descriptionText = CHANNEL_DESCRIPTION
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}