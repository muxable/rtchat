package com.rtirl.chat

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val views = HashMap<String, WebView>()

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun onDestroy() {
        // there is no corresponding onCreate because Flutter will send us the urls.
        super.onDestroy()

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        views.values.forEach { wm.removeView(it) }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/audio"
        ).setMethodCallHandler { call, result ->
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            when (call.method) {
                "set" -> {
                    val urls = (call.argument<List<String>>("urls") ?: listOf()).toHashSet()
                    (urls subtract views.keys).forEach {
                        val view = WebView(context)
                        view.settings.javaScriptEnabled = true
                        view.settings.mediaPlaybackRequiresUserGesture = false
                        view.settings.domStorageEnabled = true
                        view.settings.databaseEnabled = true
                        view.webChromeClient = object : WebChromeClient() {
                            override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                                Log.d("WebView", consoleMessage.message())
                                return true
                            }
                        }
                        view.visibility = View.INVISIBLE
                        view.setLayerType(View.LAYER_TYPE_HARDWARE, null)
                        view.loadUrl(it)

                        wm.addView(
                            view, WindowManager.LayoutParams(
                                WindowManager.LayoutParams.WRAP_CONTENT,
                                WindowManager.LayoutParams.WRAP_CONTENT,
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
                                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                                PixelFormat.OPAQUE
                            )
                        )
                        views[it] = view
                        result.success(true)
                    }
                    (views.keys subtract urls).forEach {
                        wm.removeView(views[it])
                        views.remove(it)?.destroy()
                    }
                    result.success(true)
                }
                "reload" -> {
                    val url = call.argument<String>("url")
                    if (url == null || views[url] == null) {
                        result.success(false)
                    } else {
                        views[url]?.reload()
                        result.success(true)
                    }
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

        super.configureFlutterEngine(flutterEngine)
    }
}
