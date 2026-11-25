package com.muxable.ondevicetts

import android.os.Handler
import android.os.Looper
import com.muxable.ondevicetts.supertonic.GraphSession
import com.muxable.ondevicetts.supertonic.GraphTensor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.CompletableFuture

/** Called on loader/inference threads; Flutter messages are sent on the main thread. */
internal class FlutterGraphs(messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "on_device_tts/graphs")
    private val main = Handler(Looper.getMainLooper())
    private val pending = mutableSetOf<CompletableFuture<Any?>>()
    private var detached = false

    fun detach() {
        detached = true
        pending.forEach { it.completeExceptionally(IllegalStateException("Flutter engine detached")) }
        pending.clear()
    }

    private fun call(method: String, args: Any): Any? {
        check(Looper.myLooper() != Looper.getMainLooper())
        val reply = CompletableFuture<Any?>()
        main.post {
            if (detached) {
                reply.completeExceptionally(IllegalStateException("Flutter engine detached"))
                return@post
            }
            pending.add(reply)
            channel.invokeMethod(method, args, object : MethodChannel.Result {
                override fun success(result: Any?) { pending.remove(reply); reply.complete(result) }
                override fun error(code: String, message: String?, details: Any?) {
                    pending.remove(reply)
                    reply.completeExceptionally(IllegalStateException(message ?: code))
                }
                override fun notImplemented() = error("unavailable", "Missing Dart graph handler", null)
            })
        }
        return reply.get()
    }

    fun open(file: File, threads: Int): GraphSession {
        val id = call("open", mapOf("path" to file.absolutePath, "threads" to threads)) as Number
        return object : GraphSession {
            override fun run(inputs: Map<String, GraphTensor>): GraphTensor {
                val tensors = inputs.mapValues { (_, t) -> mapOf("shape" to t.shape.toList(), "data" to t.data) }
                val out = call("run", mapOf("id" to id, "inputs" to tensors)) as Map<*, *>
                val shape = (out["shape"] as List<*>).map { (it as Number).toLong() }.toLongArray()
                return GraphTensor(out["data"] as FloatArray, shape)
            }
            override fun close() { main.post { if (!detached) channel.invokeMethod("close", id) } }
        }
    }
}
