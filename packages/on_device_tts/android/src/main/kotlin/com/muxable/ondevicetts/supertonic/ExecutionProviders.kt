package com.muxable.ondevicetts.supertonic

import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtException
import ai.onnxruntime.OrtSession
import java.io.File

/** Creates ONNX Runtime sessions on the requested execution provider. */
internal object ExecutionProviders {
    const val CPU = "cpu"
    const val XNNPACK = "xnnpack"
    const val NNAPI = "nnapi"
    const val COREML = "coreml"

    const val ALLOW_SPINNING = "session.intra_op.allow_spinning"

    /**
     * Creates a session for [file] on `settings.provider` and returns it with
     * the provider it really uses. A provider that's unknown, unavailable
     * on this platform (e.g. `coreml` on Android) or fails to take the
     * model falls back to the CPU, and [log] says so.
     */
    fun createSession(
        env: OrtEnvironment,
        file: File,
        settings: SessionSettings,
        log: (String) -> Unit,
    ): Pair<OrtSession, String> {
        if (settings.provider != CPU) {
            try {
                return options(settings).use { env.createSession(file.path, it) } to settings.provider
            } catch (e: Exception) {
                log("${settings.provider} can't run ${file.name}, falling back to cpu: ${e.message}")
            }
        }
        return options(settings.copy(provider = CPU)).use { env.createSession(file.path, it) } to CPU
    }

    private fun options(settings: SessionSettings): OrtSession.SessionOptions {
        val options = OrtSession.SessionOptions()
        try {
            val threads = settings.numThreads.coerceAtLeast(1)
            // By default the intra-op threads busy-wait for more work after
            // each parallel section, and for a while after a run ends. Chat
            // comes a message at a time with idle gaps, so spinning burns the
            // battery for nothing; blocking costs little latency (see
            // doc/native_contract.md, "Threads").
            options.addConfigEntry(ALLOW_SPINNING, "0")
            when (settings.provider) {
                CPU -> options.setIntraOpNumThreads(threads)
                XNNPACK -> {
                    // As ONNX Runtime recommends for XNNPACK: it gets the
                    // threads, and the CPU provider's pool has none.
                    options.addXnnpack(mapOf("intra_op_num_threads" to threads.toString()))
                    options.setIntraOpNumThreads(1)
                }
                NNAPI -> {
                    options.setIntraOpNumThreads(threads)
                    options.addNnapi()
                }
                else -> throw OrtException("unknown or unavailable execution provider '${settings.provider}'")
            }
        } catch (e: Exception) {
            options.close()
            throw e
        }
        return options
    }
}
