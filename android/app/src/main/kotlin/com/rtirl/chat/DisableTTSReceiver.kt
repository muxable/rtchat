package com.rtirl.chat

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.util.Log
import com.rtirl.chat.NotificationService


class DisableTTSReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context != null && intent?.action == "com.rtirl.chat.ACTION_DISABLE_TTS") {
            // Directly use the singleton instance without assigning it to a variable

            // Retrieve and cancel the notification
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(6853027)

            Log.d("DisableTTSReceiver", "Text-to-speech notification is disabled")

            // Stop the foreground service
            val serviceIntent = Intent(context, NotificationService::class.java).apply {
                putExtra("action", "ttsDisabled") // Notify the service of the action
            }

            context.startService(serviceIntent) // Note: starting, not stopping

            Log.d("DisableTTSReceiver", "Service start intent sent with action ttsDisabled")
        }
    }
}