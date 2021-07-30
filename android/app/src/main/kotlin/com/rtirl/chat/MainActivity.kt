package com.rtirl.chat

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var foregroundService: ForegroundService? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "com.rtirl.chat/foreground_service"
            )

        val connection = object : ServiceConnection {
            override fun onServiceConnected(
                className: ComponentName,
                service: IBinder
            ) {
                val binder = service as ForegroundService.ForegroundServiceBinder
                foregroundService = binder.getService()
                foregroundService?.start()
            }

            override fun onServiceDisconnected(name: ComponentName) {
                foregroundService?.stop()
                foregroundService = null
            }
        }

        channel.setMethodCallHandler { call, result ->
            val intent = Intent(this, ForegroundService::class.java)
            when (call.method) {
                "start" -> {
                    bindService(intent, connection, Context.BIND_AUTO_CREATE)
                    foregroundService?.start()
                    result.success(true)
                }
                "stop" -> {
                    foregroundService?.stop()
                    stopService(intent)
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }
}