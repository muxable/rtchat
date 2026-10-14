// The inference pipeline is ported from Supertone's reference code: the
// `supertonic` Python package (1.3.1) and the Java sample in
// https://github.com/supertone-oss-archive/supertonic, under this license:
//
// MIT License
//
// Copyright (c) 2025 Supertone Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package com.muxable.ondevicetts.supertonic

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtException
import ai.onnxruntime.OrtSession
import java.io.Closeable
import java.io.File
import java.nio.FloatBuffer
import java.nio.LongBuffer

/** The model's settings from `tts.json`. */
internal class SupertonicConfig(
    val sampleRate: Int,
    val baseChunkSize: Int,
    val chunkCompressFactor: Int,
    val latentDim: Int,
) {
    /** Audio samples per latent frame. */
    val chunkSize get() = baseChunkSize * chunkCompressFactor

    /** Latent channels. */
    val latentChannels get() = latentDim * chunkCompressFactor

    companion object {
        fun parse(json: String): SupertonicConfig {
            val root = Json.parse(json) as? Map<*, *> ?: throw IllegalArgumentException("tts.json is not an object")
            val ae = root["ae"] as? Map<*, *> ?: throw IllegalArgumentException("tts.json has no ae")
            val ttl = root["ttl"] as? Map<*, *> ?: throw IllegalArgumentException("tts.json has no ttl")
            fun int(map: Map<*, *>, key: String) =
                (map[key] as? Number)?.toInt() ?: throw IllegalArgumentException("tts.json has no $key")
            return SupertonicConfig(
                sampleRate = int(ae, "sample_rate"),
                baseChunkSize = int(ae, "base_chunk_size"),
                chunkCompressFactor = int(ttl, "chunk_compress_factor"),
                latentDim = int(ttl, "latent_dim"),
            )
        }
    }
}

/** A voice: the style vectors for the text-to-latent model and the duration predictor. */
internal class VoiceStyle(
    val id: String,
    val ttl: FloatArray,
    val ttlShape: LongArray,
    val dp: FloatArray,
    val dpShape: LongArray,
) {
    companion object {
        fun parse(id: String, json: String): VoiceStyle {
            val root = Json.parse(json) as? Map<*, *> ?: throw IllegalArgumentException("$id is not an object")
            val (ttl, ttlShape) = tensor(root, "style_ttl", id)
            val (dp, dpShape) = tensor(root, "style_dp", id)
            return VoiceStyle(id, ttl, ttlShape, dp, dpShape)
        }

        private fun tensor(root: Map<*, *>, key: String, id: String): Pair<FloatArray, LongArray> {
            val entry = root[key] as? Map<*, *> ?: throw IllegalArgumentException("$id has no $key")
            val dims = (entry["dims"] as? List<*>)?.map { (it as Number).toLong() }
                ?: throw IllegalArgumentException("$id has no $key.dims")
            val values = ArrayList<Float>()
            fun flatten(node: Any?) {
                when (node) {
                    is List<*> -> node.forEach(::flatten)
                    is Number -> values.add(node.toFloat())
                    else -> throw IllegalArgumentException("$id has a bad $key.data")
                }
            }
            flatten(entry["data"])
            val expected = dims.fold(1L) { a, b -> a * b }
            if (values.size.toLong() != expected) {
                throw IllegalArgumentException("$id: $key has ${values.size} values, dims say $expected")
            }
            return values.toFloatArray() to dims.toLongArray()
        }
    }
}

/** Receives the pipeline's intermediate tensors; used by the parity tests. */
internal interface SynthesisTrace {
    fun onIds(name: String, values: LongArray, shape: LongArray) {}
    fun onFloats(name: String, values: FloatArray, shape: LongArray) {}
}

/** Thrown when a model directory can't be loaded. */
class SupertonicLoadException(message: String, cause: Throwable? = null) : Exception(message, cause)

/** How sessions run: ONNX Runtime's execution provider and thread count. */
internal data class SessionSettings(val numThreads: Int, val provider: String)

/**
 * Supertonic 3: duration predictor → text encoder → flow-matching vector
 * estimator (N steps) → vocoder, each an ONNX Runtime session.
 */
internal class SupertonicModel(
    private val env: OrtEnvironment,
    val config: SupertonicConfig,
    val processor: SupertonicTextProcessor,
    val voices: Map<String, VoiceStyle>,
    private val durationPredictor: OrtSession,
    private val textEncoder: OrtSession,
    private val vectorEstimator: OrtSession,
    private val vocoder: OrtSession,
    /** The provider the sessions actually run on, after any fallback. */
    val provider: String,
) : Closeable {

    val sampleRate get() = config.sampleRate

    /**
     * Synthesizes [text], chunked like the reference (see [TextChunker]),
     * and hands each chunk's audio to [onAudio] as soon as it's ready, with
     * [SILENCE_SECONDS] of silence between chunks. Blank text makes no audio.
     *
     * [runOptions] lets another thread abort a run in flight with
     * `setTerminate(true)`; the run then throws [OrtException].
     */
    fun synthesize(
        text: String,
        lang: String,
        voice: VoiceStyle,
        speed: Float,
        steps: Int,
        noise: NoiseGenerator,
        runOptions: OrtSession.RunOptions,
        trace: SynthesisTrace? = null,
        onAudio: (FloatArray) -> Unit,
    ) {
        val chunks = TextChunker.chunk(text, TextChunker.maxLengthFor(lang))
        for ((i, chunk) in chunks.withIndex()) {
            if (i > 0) onAudio(FloatArray((SILENCE_SECONDS * sampleRate).toInt()))
            onAudio(infer(chunk, lang, voice, speed, steps, noise, runOptions, trace))
        }
    }

    /** One chunk through the four models; the audio trimmed to its predicted duration. */
    fun infer(
        text: String,
        lang: String,
        voice: VoiceStyle,
        speed: Float,
        steps: Int,
        noise: NoiseGenerator,
        runOptions: OrtSession.RunOptions,
        trace: SynthesisTrace? = null,
    ): FloatArray {
        val ids = processor.encode(text, lang)
        val idsShape = longArrayOf(1, ids.size.toLong())
        val maskShape = longArrayOf(1, 1, ids.size.toLong())
        val textMask = FloatArray(ids.size) { 1f }
        trace?.onIds("text_ids", ids, idsShape)

        OnnxTensor.createTensor(env, LongBuffer.wrap(ids), idsShape).use { idsTensor ->
            OnnxTensor.createTensor(env, FloatBuffer.wrap(textMask), maskShape).use { maskTensor ->
                OnnxTensor.createTensor(env, FloatBuffer.wrap(voice.ttl), voice.ttlShape).use { ttlTensor ->
                    OnnxTensor.createTensor(env, FloatBuffer.wrap(voice.dp), voice.dpShape).use { dpTensor ->
                        // Duration (seconds), scaled by speed.
                        val rawDuration = durationPredictor.run(
                            mapOf("text_ids" to idsTensor, "style_dp" to dpTensor, "text_mask" to maskTensor),
                            runOptions,
                        ).use { floats(it[0] as OnnxTensor)[0] }
                        val duration = rawDuration / speed
                        trace?.onFloats("duration", floatArrayOf(duration), longArrayOf(1))

                        return textEncoder.run(
                            mapOf("text_ids" to idsTensor, "style_ttl" to ttlTensor, "text_mask" to maskTensor),
                            runOptions,
                        ).use { encoded ->
                            val textEmb = encoded[0] as OnnxTensor
                            if (trace != null) {
                                trace.onFloats("text_emb", floats(textEmb), textEmb.info.shape)
                            }
                            denoiseAndVocode(
                                duration, steps, noise, runOptions, trace,
                                textEmb, ttlTensor, maskTensor,
                            )
                        }
                    }
                }
            }
        }
    }

    private fun denoiseAndVocode(
        duration: Float,
        steps: Int,
        noise: NoiseGenerator,
        runOptions: OrtSession.RunOptions,
        trace: SynthesisTrace?,
        textEmb: OnnxTensor,
        ttlTensor: OnnxTensor,
        maskTensor: OnnxTensor,
    ): FloatArray {
        // The reference computes these in float32.
        val wavLength = (duration * sampleRate).toLong()
        val chunkSize = config.chunkSize
        val latentLength = ((duration * sampleRate + chunkSize - 1) / chunkSize).toInt()
        val maskedLength = ((wavLength + chunkSize - 1) / chunkSize).toInt()
        val channels = config.latentChannels
        val latentShape = longArrayOf(1, channels.toLong(), latentLength.toLong())

        val latentMask = FloatArray(latentLength) { t -> if (t < maskedLength) 1f else 0f }
        var latent = noise.gaussians(channels * latentLength)
        for (c in 0 until channels) {
            for (t in 0 until latentLength) {
                latent[c * latentLength + t] *= latentMask[t]
            }
        }
        trace?.onFloats("noise", latent, latentShape)

        OnnxTensor.createTensor(env, FloatBuffer.wrap(latentMask), longArrayOf(1, 1, latentLength.toLong())).use { latentMaskTensor ->
            OnnxTensor.createTensor(env, FloatBuffer.wrap(floatArrayOf(steps.toFloat())), SCALAR_BATCH).use { totalStepTensor ->
                for (step in 0 until steps) {
                    latent = OnnxTensor.createTensor(env, FloatBuffer.wrap(floatArrayOf(step.toFloat())), SCALAR_BATCH).use { stepTensor ->
                        OnnxTensor.createTensor(env, FloatBuffer.wrap(latent), latentShape).use { latentTensor ->
                            vectorEstimator.run(
                                mapOf(
                                    "noisy_latent" to latentTensor,
                                    "text_emb" to textEmb,
                                    "style_ttl" to ttlTensor,
                                    "latent_mask" to latentMaskTensor,
                                    "text_mask" to maskTensor,
                                    "current_step" to stepTensor,
                                    "total_step" to totalStepTensor,
                                ),
                                runOptions,
                            ).use { floats(it[0] as OnnxTensor) }
                        }
                    }
                    trace?.onFloats("latent_$step", latent, latentShape)
                }
            }
        }

        val wav = OnnxTensor.createTensor(env, FloatBuffer.wrap(latent), latentShape).use { latentTensor ->
            vocoder.run(mapOf("latent" to latentTensor), runOptions).use { floats(it[0] as OnnxTensor) }
        }
        trace?.onFloats("wav", wav, longArrayOf(1, wav.size.toLong()))
        val trimmed = (sampleRate * duration).toInt().coerceIn(0, wav.size)
        return if (trimmed == wav.size) wav else wav.copyOf(trimmed)
    }

    override fun close() {
        durationPredictor.close()
        textEncoder.close()
        vectorEstimator.close()
        vocoder.close()
    }

    companion object {
        /** Silence between chunks of one text, as in the reference. */
        const val SILENCE_SECONDS = 0.3f

        /** The reference's speed limits. */
        const val MIN_SPEED = 0.7f
        const val MAX_SPEED = 2.0f

        const val MIN_STEPS = 1
        const val MAX_STEPS = 100

        /** The shape of a per-batch scalar, with a batch of one. */
        private val SCALAR_BATCH = longArrayOf(1)

        private val MODEL_NAMES = listOf("duration_predictor", "text_encoder", "vector_estimator", "vocoder")

        private fun floats(tensor: OnnxTensor): FloatArray {
            val buffer = tensor.floatBuffer
            return FloatArray(buffer.remaining()).also { buffer.get(it) }
        }

        /** The model directory's ONNX files: `onnx/` when present, else the directory itself. */
        fun onnxDir(dir: File): File = File(dir, "onnx").takeIf { it.isDirectory } ?: dir

        /** `<name>.onnx`, or the quantized `<name>.int8.onnx`. */
        fun modelFile(onnxDir: File, name: String): File? =
            listOf("$name.onnx", "$name.int8.onnx").map { File(onnxDir, it) }.firstOrNull { it.isFile }

        /** Voice ids (the style file names) and their files, sorted by id. */
        fun voiceFiles(dir: File): List<Pair<String, File>> =
            (File(dir, "voice_styles").listFiles() ?: emptyArray())
                .filter { it.isFile && it.name.endsWith(".json") }
                .map { it.name.removeSuffix(".json") to it }
                .sortedBy { it.first }

        /**
         * Loads the model in [dir], laid out like the `Supertone/supertonic-3`
         * repository: `onnx/` with `tts.json`, `unicode_indexer.json` and the
         * four models, and `voice_styles/` with one JSON file per voice.
         */
        fun load(
            env: OrtEnvironment,
            dir: File,
            settings: SessionSettings,
            log: (String) -> Unit,
        ): SupertonicModel {
            if (!dir.isDirectory) throw SupertonicLoadException("Model directory not found: $dir")
            val onnx = onnxDir(dir)
            val config = try {
                SupertonicConfig.parse(File(onnx, "tts.json").readText())
            } catch (e: Exception) {
                throw SupertonicLoadException("Can't read tts.json in $onnx: ${e.message}", e)
            }
            val indexer = try {
                val list = Json.parse(File(onnx, "unicode_indexer.json").readText()) as List<*>
                IntArray(list.size) { (list[it] as Number).toInt() }
            } catch (e: Exception) {
                throw SupertonicLoadException("Can't read unicode_indexer.json in $onnx: ${e.message}", e)
            }
            val voices = voiceFiles(dir).associate { (id, file) ->
                id to try {
                    VoiceStyle.parse(id, file.readText())
                } catch (e: Exception) {
                    throw SupertonicLoadException("Can't read voice style $file: ${e.message}", e)
                }
            }
            if (voices.isEmpty()) throw SupertonicLoadException("No voice styles in $dir/voice_styles")
            val files = MODEL_NAMES.map { name ->
                modelFile(onnx, name) ?: throw SupertonicLoadException("Missing $name.onnx in $onnx")
            }

            val sessions = ArrayList<OrtSession>()
            var provider = settings.provider
            try {
                for (file in files) {
                    val (session, used) = ExecutionProviders.createSession(env, file, settings.copy(provider = provider), log)
                    // Once a provider fails, use the CPU for the rest too.
                    provider = used
                    sessions.add(session)
                }
            } catch (e: OrtException) {
                sessions.forEach { it.close() }
                throw SupertonicLoadException("Can't load the model in $onnx: ${e.message}", e)
            }
            return SupertonicModel(
                env, config, SupertonicTextProcessor(indexer), voices,
                sessions[0], sessions[1], sessions[2], sessions[3], provider,
            )
        }
    }
}
