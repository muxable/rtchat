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
import com.rtirl.chat.R

class NotificationService : Service() {
    companion object {
        const val CHANNEL_ID = "NotificationServiceChannel"
        const val NOTIFICATION_ID = 6853027
        const val CHANNEL_NAME  = "Text-to-Speech Notification"
        const val CHANNEL_DESCRIPTION = "Text-to-speech is enabled"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.getStringExtra("action")) {
            "dismissNotification" -> {
                val notificationId = intent.getIntExtra("id", 0)
                dismissNotification(notificationId)
            }
            else -> {
                // Your existing code to show the notification...

                val notificationIntent = Intent(this, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                        this,
                        0, notificationIntent, 0
                )

                val disableIntent = Intent(this, NotificationService::class.java).apply {
                    putExtra("action", "disableTTS")
                }
                val disablePendingIntent: PendingIntent =
                        PendingIntent.getService(this, 0, disableIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or
                                        PendingIntent.FLAG_IMMUTABLE)
                                        
                val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                        .setContentTitle("Text-to-speech is enabled")
                        .setContentText("")
                        .setSmallIcon(R.drawable.notification_icon)
                        .setContentIntent(pendingIntent)
                        .build()

                startForeground(NOTIFICATION_ID, notification)

                Log.d("NotificationService", "startForeground called")

            "showNotification" -> {
                showNotification()
            }
            "dismissNotification" -> {
                dismissNotification(NOTIFICATION_ID)
            }
        }
        return START_NOT_STICKY
    }

    private fun showNotification() {

        Log.d("NotificationService", "showNotification called")
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        
        val dismissIntent = Intent(this, NotificationService::class.java).apply {
            putExtra("action", "dismissNotification")
        }
        val dismissPendingIntent = PendingIntent.getService(this, 0, dismissIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Text-to-Speech Notification")
            .setContentText("Text-to-speech is enabled")
            .setSmallIcon(R.drawable.notification_icon)
            .addAction(R.drawable.text_to_speech, "Disable TTS", dismissPendingIntent)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun dismissNotification(notificationId: Int) {
        Log.d("NotificationService", "dismissNotification called")
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
    }

    override fun onBind(intent: Intent): IBinder? {
        // This service is not bound to any component
        return null
    }

    private fun createNotificationChannel() {

        Log.d("NotificationService", "createNotificationChannel called")

        if(notificationManager?.getNotificationChannel(CHANNEL_ID) == null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val serviceChannel = NotificationChannel(
                        CHANNEL_ID,
                        "tts_notifications_key",
                        NotificationManager.IMPORTANCE_DEFAULT
                )
                
                notificationManager?.createNotificationChannel(serviceChannel)
            }
            // Register the channel with the system
            val notificationManager: NotificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}