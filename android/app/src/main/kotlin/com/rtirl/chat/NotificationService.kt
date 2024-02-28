package com.rtirl.chat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import com.rtirl.chat.R

class NotificationService : Service() {

    private var notificationManager: NotificationManager? = null
    private lateinit var tts: TextToSpeech

    companion object {
        const val CHANNEL_ID = "ForegroundServiceChannel"
        const val NOTIFICATION_ID = 6853027
    }

    override fun onCreate() {
        super.onCreate()

        Log.d("NotificationService", "onCreate called")


        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        createNotificationChannel()

        tts = TextToSpeech(this) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("NotificationService", "onStartCommand called")
        when (intent?.getStringExtra("action")) {
            "dismissNotification" -> {
                val notificationId = intent.getIntExtra("id", 0)
                dismissNotification(notificationId)
                if (tts.isSpeaking) {
                    tts.stop()
                    Log.d("TTS", "Stopped speaking")
                }
            }
            else -> {

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
                        .addAction(R.drawable.text_to_speech, "Disable TTS", disablePendingIntent)
                .build()

                startForeground(NOTIFICATION_ID, notification)

                Log.d("NotificationService", "startForeground called")


                // Do heavy work on a background thread
                // stopSelf();
            }
        }


        return START_NOT_STICKY
    }

    private fun dismissNotification(id: Int) {
        notificationManager?.cancel(id)
    }

    override fun onBind(intent: Intent): IBinder? {
        // Used only in case of bound services.
        return null
    }

    override fun onDestroy() {
        super.onDestroy()

        stopForeground(true)

        Log.d("NotificationService", "onDestroy called")

        dismissNotification(NOTIFICATION_ID)
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
        }

    }
}