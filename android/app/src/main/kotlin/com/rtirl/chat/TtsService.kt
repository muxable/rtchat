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
 * Foreground service that runs while text to speech is on. Without it Android freezes the app
 * shortly after it's backgrounded and mutes its audio, so chat stops being read out mid-stream.
 */
class TtsService : Service() {

  companion object {
    private const val CHANNEL_ID = "tts"
    private const val CHANNEL_NAME = "Text to speech"
    private const val NOTIFICATION_ID = 6853027

    private const val ACTION_START = "com.rtirl.chat.tts.START"
    private const val ACTION_TURN_OFF = "com.rtirl.chat.tts.TURN_OFF"

    private const val EXTRA_TITLE = "title"
    private const val EXTRA_TEXT = "text"
    private const val EXTRA_TURN_OFF = "turnOff"

    /** Set by MainActivity so the notification can turn TTS off in Dart. */
    var channel: MethodChannel? = null

    @Volatile
    var isRunning = false
      private set

    fun start(
        context: Context,
        title: String,
        text: String,
        turnOff: String,
    ) {
      val intent =
          Intent(context, TtsService::class.java).apply {
            action = ACTION_START
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_TEXT, text)
            putExtra(EXTRA_TURN_OFF, turnOff)
          }

      ContextCompat.startForegroundService(context, intent)
    }

    fun stop(context: Context) {
      context.stopService(Intent(context, TtsService::class.java))
    }
  }

  private lateinit var notificationManager: NotificationManager
  private lateinit var contentPendingIntent: PendingIntent
  private lateinit var turnOffPendingIntent: PendingIntent

  private var channelCreated = false
  private var lastTitle: String? = null
  private var lastText: String? = null
  private var lastTurnOff: String? = null
  private var foregroundStarted = false

  override fun onCreate() {
    super.onCreate()

    notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    ensureChannel()
    createPendingIntents()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(
      intent: Intent?,
      flags: Int,
      startId: Int,
  ): Int {
    if (intent?.action == ACTION_TURN_OFF) {
      channel?.invokeMethod("turnOff", null)
      stopSelf()
      return START_NOT_STICKY
    }

    val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Text to speech"
    val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
    val turnOff = intent?.getStringExtra(EXTRA_TURN_OFF) ?: "Turn off"

    val unchanged =
        foregroundStarted && title == lastTitle && text == lastText && turnOff == lastTurnOff

    if (!unchanged) {
      val notification = buildNotification(title, text, turnOff)

      ServiceCompat.startForeground(
          this,
          NOTIFICATION_ID,
          notification,
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
          } else {
            0
          },
      )

      lastTitle = title
      lastText = text
      lastTurnOff = turnOff
      foregroundStarted = true
    }

    isRunning = true
    return START_NOT_STICKY
  }

  override fun onDestroy() {
    isRunning = false
    foregroundStarted = false
    lastTitle = null
    lastText = null
    lastTurnOff = null

    super.onDestroy()
  }

  private fun ensureChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      notificationManager.createNotificationChannel(
          NotificationChannel(
              CHANNEL_ID,
              CHANNEL_NAME,
              NotificationManager.IMPORTANCE_LOW,
          )
      )
    }
  }

  private fun createPendingIntents() {
    val flags =
        PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
              PendingIntent.FLAG_IMMUTABLE
            } else {
              0
            }

    contentPendingIntent =
        PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            flags,
        )

    turnOffPendingIntent =
        PendingIntent.getService(
            this,
            1,
            Intent(this, TtsService::class.java).setAction(ACTION_TURN_OFF),
            flags,
        )
  }

  private fun buildNotification(
      title: String,
      text: String,
      turnOff: String,
  ) =
      NotificationCompat.Builder(this, CHANNEL_ID)
          .setContentTitle(title)
          .setContentText(text)
          .setSmallIcon(R.drawable.notification_icon)
          .setOngoing(true)
          .setSilent(true)
          .setContentIntent(contentPendingIntent)
          .addAction(
              R.drawable.text_to_speech,
              turnOff,
              turnOffPendingIntent,
          )
          .build()
}
