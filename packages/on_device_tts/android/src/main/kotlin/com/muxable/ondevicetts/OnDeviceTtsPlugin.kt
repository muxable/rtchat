package com.muxable.ondevicetts

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the `on_device_tts/onnx` channels; see `doc/native_contract.md`
 * in the package for the contract.
 */
class OnDeviceTtsPlugin : FlutterPlugin {
    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var engine: OnnxTtsChannelHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
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
        methods = MethodChannel(binding.binaryMessenger, OnnxTtsChannelHandler.METHOD_CHANNEL).also {
            it.setMethodCallHandler(handler)
        }
        events = EventChannel(binding.binaryMessenger, OnnxTtsChannelHandler.EVENT_CHANNEL).also {
            it.setStreamHandler(handler)
        }
        engine = handler
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        engine?.dispose()
        methods = null
        events = null
        engine = null
    }
}
