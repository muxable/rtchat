package com.muxable.ondevicetts

import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.util.Log
import com.muxable.ondevicetts.supertonic.ExecutionProviders
import com.muxable.ondevicetts.supertonic.NoiseGenerator
import com.muxable.ondevicetts.supertonic.SessionSettings
import com.muxable.ondevicetts.supertonic.SupertonicLanguages
import com.muxable.ondevicetts.supertonic.SupertonicLoadException
import com.muxable.ondevicetts.supertonic.SupertonicModel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.SecureRandom
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Handles `on_device_tts/onnx` calls and feeds `on_device_tts/onnx/events`.
 *
 * Calls arrive on the main thread. Models load on a loader thread; all
 * inference runs on one synthesis thread; audio is written on a playback
 * thread. Results and events go back on the main thread.
 *
 * [activity] keeps the CPU awake while a model loads and while an utterance
 * is active.
 */
internal class OnnxTtsChannelHandler(
    private val activity: ActivityLock,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        const val METHOD_CHANNEL = "on_device_tts/onnx"
        const val EVENT_CHANNEL = "on_device_tts/onnx/events"
        private const val TAG = "OnDeviceTts"
    }

    private val main = Handler(Looper.getMainLooper())
    private val env: OrtEnvironment by lazy { OrtEnvironment.getEnvironment() }
    private val models = ConcurrentHashMap<String, SupertonicModel>()
    private val nextHandle = AtomicInteger(1)
    private val random = SecureRandom()

    // ONNX Runtime starts a session's intra-op threads on the thread that
    // creates it, and threads inherit its priority: loading at background
    // priority would leave half of every inference at background priority,
    // which a busy foreground app (e.g. the streaming app) starves.
    private val loader = executor("on_device_tts-load", Process.THREAD_PRIORITY_DEFAULT)
    private val synthesis = executor("on_device_tts-synth", Process.THREAD_PRIORITY_DEFAULT)

    // Mostly blocked in AudioTrack.write; audio priority so it refills the
    // track on time. URGENT_AUDIO is for the audio system's own threads.
    private val playback = executor("on_device_tts-play", Process.THREAD_PRIORITY_AUDIO)

    /** The utterance being spoken; only touched on the main thread. */
    private var active: Utterance? = null
    private var sink: EventChannel.EventSink? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "load" -> load(call, result)
                "voices" -> voices(call, result)
                "speak" -> speak(call, result)
                "synthesize" -> synthesize(call, result)
                "stop" -> {
                    stop()
                    result.success(null)
                }
                "unload" -> unload(call, result)
                else -> result.notImplemented()
            }
        } catch (e: BadArgs) {
            result.error("bad_args", e.message, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun dispose() {
        stop()
        sink = null
        synthesis.execute {
            models.values.forEach { it.close() }
            models.clear()
        }
        loader.shutdown()
        synthesis.shutdown()
        playback.shutdown()
    }

    private fun load(call: MethodCall, result: MethodChannel.Result) {
        val modelType = call.string("modelType")
        val modelDir = call.string("modelDir")
        val numThreads = call.int("numThreads") ?: 2
        val provider = call.argument<String>("provider") ?: ExecutionProviders.CPU
        if (modelType != "supertonic") {
            result.error("load_failed", "Unknown model type: $modelType", null)
            return
        }
        if (numThreads < 1) throw BadArgs("numThreads must be at least 1")
        val hold = activity.hold()
        loader.execute {
            try {
                val started = SystemClock.elapsedRealtime()
                val model = SupertonicModel.load(
                    env, File(modelDir), SessionSettings(numThreads, provider),
                ) { Log.w(TAG, it) }
                val handle = "supertonic-${nextHandle.getAndIncrement()}"
                models[handle] = model
                Log.i(
                    TAG,
                    "Loaded $modelDir as $handle on ${model.provider} with $numThreads threads " +
                        "in ${SystemClock.elapsedRealtime() - started} ms",
                )
                main.post { result.success(handle) }
            } catch (e: SupertonicLoadException) {
                main.post { result.error("load_failed", e.message, null) }
            } catch (e: Throwable) {
                Log.e(TAG, "Loading $modelDir failed", e)
                main.post { result.error("load_failed", e.toString(), null) }
            } finally {
                hold.close()
            }
        }
    }

    private fun voices(call: MethodCall, result: MethodChannel.Result) {
        val model = model(call)
        result.success(model.voices.keys.map { mapOf("id" to it, "name" to it) })
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val requested = SystemClock.elapsedRealtimeNanos()
        val model = model(call)
        val utteranceId = call.string("utteranceId")
        val segments = call.argument<List<*>>("segments")?.map { it as? String ?: throw BadArgs("segments must be strings") }
            ?: throw BadArgs("Missing segments")
        val request = request(call, model)
        if (active != null) {
            result.error("busy", "Already speaking ${active!!.id}", null)
            return
        }

        val utterance = Utterance(utteranceId, requested, result, activity.hold())
        active = utterance

        synthesis.execute {
            try {
                for (segment in segments) {
                    if (utterance.cancelled) break
                    model.synthesize(
                        segment, request.lang, request.voice, request.speed, request.steps,
                        NoiseGenerator(random.nextLong()), utterance.runOptions,
                    ) { utterance.queue.put(Chunk.Audio(it)) }
                }
                utterance.queue.put(Chunk.End)
            } catch (e: Throwable) {
                utterance.queue.put(if (utterance.cancelled) Chunk.End else Chunk.Failed(e))
            } finally {
                utterance.closeRunOptions()
            }
        }

        playback.execute { play(utterance, model.sampleRate) }
    }

    private fun play(utterance: Utterance, sampleRate: Int) {
        var outcome: Outcome = Outcome.Stopped
        var player: PcmPlayer? = null
        try {
            player = PcmPlayer(sampleRate)
            utterance.player = player
            if (utterance.cancelled) player.halt()
            var announced = false
            val announce = {
                if (!announced) {
                    announced = true
                    emit(utterance, "firstAudio")
                }
            }
            while (true) {
                if (utterance.cancelled) break
                when (val chunk = utterance.queue.poll(50, TimeUnit.MILLISECONDS) ?: continue) {
                    is Chunk.Audio -> {
                        if (!player.write(chunk.pcm, announce)) break
                    }
                    is Chunk.End -> {
                        if (player.drain(player.framesWritten)) outcome = Outcome.Done
                        break
                    }
                    is Chunk.Failed -> {
                        outcome = Outcome.Failed(chunk.error)
                        break
                    }
                }
            }
        } catch (e: Throwable) {
            outcome = Outcome.Failed(e)
        } finally {
            player?.release()
        }
        if (outcome is Outcome.Failed) {
            // Don't keep synthesizing audio nobody will play.
            utterance.cancel()
        } else if (utterance.cancelled) {
            outcome = Outcome.Stopped
        }
        finish(utterance, outcome)
    }

    private fun finish(utterance: Utterance, outcome: Outcome) {
        main.post {
            utterance.hold.close()
            if (active === utterance) active = null
            when (outcome) {
                Outcome.Done -> {
                    sendEvent(utterance, "done")
                    utterance.result.success(null)
                }
                Outcome.Stopped -> {
                    sendEvent(utterance, "stopped")
                    utterance.result.success(null)
                }
                is Outcome.Failed -> {
                    Log.e(TAG, "Speaking ${utterance.id} failed", outcome.error)
                    val message = outcome.error.message ?: outcome.error.toString()
                    sendEvent(utterance, "error", message)
                    utterance.result.error("speak_failed", message, null)
                }
            }
        }
    }

    private fun emit(utterance: Utterance, type: String) {
        main.post { sendEvent(utterance, type) }
    }

    private fun sendEvent(utterance: Utterance, type: String, message: String? = null) {
        val event = mutableMapOf<String, Any>(
            "utteranceId" to utterance.id,
            "type" to type,
            "elapsedMs" to (SystemClock.elapsedRealtimeNanos() - utterance.requestedNanos) / 1_000_000,
        )
        if (message != null) event["message"] = message
        sink?.success(event)
    }

    private fun stop() {
        active?.cancel()
    }

    private fun synthesize(call: MethodCall, result: MethodChannel.Result) {
        val model = model(call)
        val text = call.string("text")
        val request = request(call, model)
        val seed = call.argument<Number>("noiseSeed")?.toLong()
        synthesis.execute {
            try {
                val pieces = ArrayList<FloatArray>()
                OrtSession.RunOptions().use { runOptions ->
                    model.synthesize(
                        text, request.lang, request.voice, request.speed, request.steps,
                        NoiseGenerator(seed ?: random.nextLong()), runOptions,
                    ) { pieces.add(it) }
                }
                val pcm = FloatArray(pieces.sumOf { it.size })
                var offset = 0
                for (piece in pieces) {
                    piece.copyInto(pcm, offset)
                    offset += piece.size
                }
                main.post { result.success(mapOf("sampleRate" to model.sampleRate, "pcm" to pcm)) }
            } catch (e: Throwable) {
                Log.e(TAG, "Synthesizing failed", e)
                main.post { result.error("synthesis_failed", e.message ?: e.toString(), null) }
            }
        }
    }

    private fun unload(call: MethodCall, result: MethodChannel.Result) {
        val handle = call.string("handle")
        val model = models.remove(handle)
        if (model == null) {
            result.success(null)
            return
        }
        // Utterances on this model stop; queued synthesis runs first.
        stop()
        synthesis.execute {
            model.close()
            main.post { result.success(null) }
        }
    }

    private class Request(
        val lang: String,
        val voice: com.muxable.ondevicetts.supertonic.VoiceStyle,
        val speed: Float,
        val steps: Int,
    )

    private fun request(call: MethodCall, model: SupertonicModel): Request {
        val language = call.string("language")
        val voiceId = call.string("voiceId")
        val voice = model.voices[voiceId] ?: throw BadArgs("Unknown voice: $voiceId")
        val speed = (call.argument<Number>("speed")?.toFloat() ?: 1f)
            .coerceIn(SupertonicModel.MIN_SPEED, SupertonicModel.MAX_SPEED)
        val steps = call.int("steps") ?: 5
        if (steps !in SupertonicModel.MIN_STEPS..SupertonicModel.MAX_STEPS) {
            throw BadArgs("steps must be between ${SupertonicModel.MIN_STEPS} and ${SupertonicModel.MAX_STEPS}")
        }
        return Request(SupertonicLanguages.resolve(language), voice, speed, steps)
    }

    private fun model(call: MethodCall): SupertonicModel {
        val handle = call.string("handle")
        return models[handle] ?: throw BadArgs("Unknown handle: $handle")
    }

    private class BadArgs(message: String) : Exception(message)

    private fun MethodCall.string(name: String): String =
        argument<String>(name) ?: throw BadArgs("Missing $name")

    private fun MethodCall.int(name: String): Int? = argument<Number>(name)?.toInt()

    private sealed class Chunk {
        class Audio(val pcm: FloatArray) : Chunk()
        object End : Chunk()
        class Failed(val error: Throwable) : Chunk()
    }

    private sealed class Outcome {
        object Done : Outcome()
        object Stopped : Outcome()
        class Failed(val error: Throwable) : Outcome()
    }

    private class Utterance(
        val id: String,
        val requestedNanos: Long,
        val result: MethodChannel.Result,
        /** Keeps the CPU awake until the utterance has finished. */
        val hold: AutoCloseable,
    ) {
        val queue = LinkedBlockingQueue<Chunk>()
        val runOptions = OrtSession.RunOptions()

        @Volatile
        var cancelled = false

        @Volatile
        var player: PcmPlayer? = null

        private var runOptionsClosed = false

        fun cancel() {
            cancelled = true
            synchronized(this) {
                // Aborts the ONNX Runtime run in flight.
                if (!runOptionsClosed) runOptions.setTerminate(true)
            }
            player?.halt()
        }

        fun closeRunOptions() {
            synchronized(this) {
                runOptionsClosed = true
                runOptions.close()
            }
        }
    }

    private fun executor(name: String, priority: Int): ExecutorService =
        Executors.newSingleThreadExecutor { runnable ->
            Thread({
                Process.setThreadPriority(priority)
                runnable.run()
            }, name)
        }
}
