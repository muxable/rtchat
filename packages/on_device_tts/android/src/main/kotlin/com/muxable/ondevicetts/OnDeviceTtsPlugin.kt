package com.muxable.ondevicetts

import android.app.ActivityManager
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the `on_device_tts/onnx` channels and `on_device_tts/memory`;
 * see `doc/native_contract.md` in the package for the contract.
 */
class OnDeviceTtsPlugin : FlutterPlugin {
    companion object {
        const val MEMORY_CHANNEL = "on_device_tts/memory"
    }

    private val systemTts = SystemTtsPlugin()

    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var memoryEvents: EventChannel? = null
    private var engine: OnnxTtsChannelHandler? = null
    private var context: Context? = null
    private var memory: MemoryEvents? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onAttachedToEngine(binding)
        val power = binding.applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "on_device_tts:speak").apply {
            setReferenceCounted(false)
        }
        val activity = ActivityLock(
            ActivityLock.DEFAULT_TIMEOUT_MS,
            acquire = { wakeLock.acquire(it) },
            release = { if (wakeLock.isHeld) wakeLock.release() },
        )
        val handler = OnnxTtsChannelHandler(activity)
        val context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, OnnxTtsChannelHandler.METHOD_CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "deviceMemory") {
                    result.success(deviceMemory(context))
                } else {
                    handler.onMethodCall(call, result)
                }
            }
        }
        events = EventChannel(binding.binaryMessenger, OnnxTtsChannelHandler.EVENT_CHANNEL).also {
            it.setStreamHandler(handler)
        }
        engine = handler

        val memory = MemoryEvents()
        memoryEvents = EventChannel(binding.binaryMessenger, MEMORY_CHANNEL).also {
            it.setStreamHandler(memory)
        }
        context.registerComponentCallbacks(memory)
        this.memory = memory
        this.context = context
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        systemTts.onDetachedFromEngine(binding)
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        memoryEvents?.setStreamHandler(null)
        memory?.let { context?.unregisterComponentCallbacks(it) }
        engine?.dispose()
        methods = null
        events = null
        memoryEvents = null
        memory = null
        context = null
        engine = null
    }

    private fun deviceMemory(context: Context): Map<String, Any> {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        return mapOf(
            "totalBytes" to info.totalMem,
            "availableBytes" to info.availMem,
            "lowRamDevice" to manager.isLowRamDevice,
        )
    }

    /**
     * Sends `{level}` to Dart for the trim levels that should release the
     * models ([MemoryPressure.shouldRelease]), and for `onLowMemory`.
     */
    private class MemoryEvents : EventChannel.StreamHandler, ComponentCallbacks2 {
        private val main = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }

        override fun onTrimMemory(level: Int) {
            if (MemoryPressure.shouldRelease(level)) send(level)
        }

        @Deprecated("Deprecated in Java")
        override fun onLowMemory() = send(MemoryPressure.LOW_MEMORY)

        override fun onConfigurationChanged(newConfig: Configuration) {}

        private fun send(level: Int) {
            main.post { sink?.success(mapOf("level" to level)) }
        }
    }
}
