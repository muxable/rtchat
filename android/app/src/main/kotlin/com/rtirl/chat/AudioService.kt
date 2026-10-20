package com.rtirl.chat

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.view.WindowManager
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.app.NotificationCompat
import androidx.multidex.BuildConfig
import io.flutter.Log

class AudioService : Service() {

  companion object {
    private const val NOTIFICATION_ID = 68448
    private const val CHANNEL_ID = "AudioSources"
    private const val WAKE_LOCK_TAG = "RealtimeChat::Wakelock"
    private const val EXTRA_URLS = "urls"
    private const val PACKAGE_NAME = BuildConfig.APPLICATION_ID + ".AudioService"
    const val ACTION_START_SERVICE = "$PACKAGE_NAME.start_service"
    const val ACTION_RELOAD_SOURCES = "$PACKAGE_NAME.reload_sources"
  }

  private val views = mutableMapOf<String, WebView>()

  private var wakeLock: PowerManager.WakeLock? = null
  private var windowManager: WindowManager? = null
  private var notificationManager: NotificationManager? = null
  private var notificationChannelCreated = false
  private var contentPendingIntent: PendingIntent? = null

  override fun onCreate() {
    super.onCreate()

    windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    createNotificationChannel()
    createWakeLock()
    createContentPendingIntent()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  @SuppressLint("SetJavaScriptEnabled")
  override fun onStartCommand(
      intent: Intent?,
      flags: Int,
      startId: Int,
  ): Int {
    val requestedUrls = intent?.getStringArrayListExtra(EXTRA_URLS)?.toSet()

    when {
      requestedUrls != null -> updateSources(requestedUrls)

      intent?.action == ACTION_RELOAD_SOURCES -> {
        // Reload only when explicitly requested.
        views.values.forEach { it.reload() }
      }

      // A start without URLs must not reload active sources.
      else -> Unit
    }

    if (views.isEmpty()) {
      stopAudioService()
      return START_NOT_STICKY
    }

    startForeground(NOTIFICATION_ID, buildNotification())
    acquireWakeLockIfNeeded()

    return START_STICKY
  }

  private fun createWakeLock() {
    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

    wakeLock =
        powerManager
            .newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                WAKE_LOCK_TAG,
            )
            .apply {
              // Repeated acquire() calls cannot increment a reference count.
              setReferenceCounted(false)
            }
  }

  private fun acquireWakeLockIfNeeded() {
    val lock = wakeLock ?: return

    if (!lock.isHeld) {
      lock.acquire()
    }
  }

  private fun releaseWakeLock() {
    wakeLock?.let { lock ->
      if (lock.isHeld) {
        lock.release()
      }
    }
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || notificationChannelCreated) {
      return
    }

    val channel =
        NotificationChannel(
                CHANNEL_ID,
                "Audio Sources",
                NotificationManager.IMPORTANCE_MIN,
            )
            .apply {
              setSound(null, null)
              enableVibration(false)
              setShowBadge(false)
            }

    notificationManager?.createNotificationChannel(channel)
    notificationChannelCreated = true
  }

  private fun createContentPendingIntent() {
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return

    val pendingIntentFlags =
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
            launchIntent,
            pendingIntentFlags,
        )
  }

  private fun buildNotification() =
      NotificationCompat.Builder(this, CHANNEL_ID)
          .setContentTitle("RealtimeChat Audio Sources")
          .setContentText("Keeping audio sources active.")
          .setOngoing(true)
          .setPriority(NotificationCompat.PRIORITY_MIN)
          .setSmallIcon(R.drawable.notification_icon)
          .setContentIntent(contentPendingIntent)
          .build()

  private fun updateSources(requestedUrls: Set<String>) {
    views.keys.toList().filterNot(requestedUrls::contains).forEach(::removeSource)

    requestedUrls.forEach { url ->
      if (url !in views) {
        addSource(url)
      }
    }
  }

  @SuppressLint("SetJavaScriptEnabled")
  private fun addSource(url: String) {
    val wm = windowManager ?: return

    val webView = WebView(this)

    try {
      webView.settings.apply {
        javaScriptEnabled = true
        mediaPlaybackRequiresUserGesture = false
        domStorageEnabled = true
        databaseEnabled = true
        mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
      }

      webView.webChromeClient = object : WebChromeClient() {
          override fun onConsoleMessage(
            consoleMessage: ConsoleMessage
            ): Boolean {
        Log.d("WebView", consoleMessage.message())
        return true
      }
    }

      webView.webViewClient =
          object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?,
            ): Boolean = false
          }

      val params =
          WindowManager.LayoutParams(
              0,
              0,
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
              } else {
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
              },
              WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                  WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
              PixelFormat.TRANSPARENT,
          )

      wm.addView(webView, params)
      views[url] = webView

      // Configure clients before starting navigation.
      webView.loadUrl(url)
    } catch (e: Exception) {
      // Avoid retaining a partially initialized WebView.
      try {
        if (webView.parent != null) {
          wm.removeViewImmediate(webView)
        }
      } catch (_: Exception) {
        // Best-effort cleanup.
      }

      webView.stopLoading()
      webView.destroy()
    }
  }

  private fun removeSource(url: String) {
    val webView = views.remove(url) ?: return

    webView.stopLoading()
    webView.webChromeClient = null

    try {
      if (webView.parent != null) {
        windowManager?.removeViewImmediate(webView)
      }
    } catch (_: Exception) {
      // Continue cleanup if the window has already been detached.
    }

    webView.destroy()
  }

  private fun stopAudioService() {
    stopForeground(true)
    notificationManager?.cancel(NOTIFICATION_ID)
    releaseWakeLock()
    stopSelf()
  }

  override fun onDestroy() {
    views.keys.toList().forEach(::removeSource)
    releaseWakeLock()

    wakeLock = null
    windowManager = null
    notificationManager = null
    contentPendingIntent = null

    super.onDestroy()
  }
}
