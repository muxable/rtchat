package com.muxable.ondevicetts.supertonic

import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import org.junit.jupiter.api.Assumptions.assumeTrue
import org.junit.jupiter.api.Test
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Compares the pipeline, tensor by tensor, with reference output from
 * Supertone's `supertonic` Python package.
 *
 * Skipped unless `SUPERTONIC_PARITY_DIR` points at a directory made by
 * `tool/supertonic_reference.py`, which holds `manifest.json` and the
 * reference tensors as little-endian binaries; the manifest names the model
 * directory. Run it with
 * `SUPERTONIC_PARITY_DIR=... ./gradlew :on_device_tts:testDebugUnitTest`
 * from the app's `android/` (the variable also puts the desktop ONNX Runtime
 * on the test classpath).
 */
class ReferenceParityTest {
    private class Trace : SynthesisTrace {
        val ids = HashMap<String, LongArray>()
        val floats = HashMap<String, FloatArray>()
        val shapes = HashMap<String, LongArray>()

        override fun onIds(name: String, values: LongArray, shape: LongArray) {
            ids[name] = values
            shapes[name] = shape
        }

        override fun onFloats(name: String, values: FloatArray, shape: LongArray) {
            floats[name] = values
            shapes[name] = shape
        }
    }

    @Test
    fun `matches the reference implementation`() {
        val dir = System.getenv("SUPERTONIC_PARITY_DIR")
        assumeTrue(dir != null, "SUPERTONIC_PARITY_DIR isn't set")
        val root = File(dir!!)
        val manifest = Json.parse(File(root, "manifest.json").readText()) as Map<*, *>
        val tolerances = (manifest["tolerances"] as Map<*, *>).mapValues { (it.value as Number).toDouble() }

        val env = OrtEnvironment.getEnvironment()
        val model = SupertonicModel.load(
            env, File(manifest["model_dir"] as String), SessionSettings(numThreads = 2, provider = "cpu"),
        ) { println(it) }

        val report = StringBuilder()
        var worstWav = 0.0
        model.use {
            for (case in manifest["cases"] as List<*>) {
                case as Map<*, *>
                val name = case["name"] as String
                val trace = Trace()
                val pcm = OrtSession.RunOptions().use { runOptions ->
                    model.infer(
                        case["text"] as String,
                        case["lang"] as String,
                        model.voices.getValue(case["voice"] as String),
                        (case["speed"] as Number).toFloat(),
                        (case["steps"] as Number).toInt(),
                        NoiseGenerator((case["seed"] as Number).toLong()),
                        runOptions,
                        trace,
                    )
                }

                for ((tensorName, spec) in case["tensors"] as Map<*, *>) {
                    tensorName as String
                    spec as Map<*, *>
                    val shape = (spec["shape"] as List<*>).map { (it as Number).toLong() }.toLongArray()
                    val file = File(root, spec["file"] as String)
                    if (spec["dtype"] == "int64") {
                        assertContentEquals(readLongs(file), trace.ids[tensorName], "$name $tensorName")
                        report.append("$name $tensorName: exact\n")
                        continue
                    }
                    val actual = trace.floats[tensorName] ?: error("$name: no $tensorName")
                    assertContentEquals(shape, trace.shapes[tensorName], "$name $tensorName shape")
                    val expected = readFloats(file)
                    assertEquals(expected.size, actual.size, "$name $tensorName size")
                    val diff = maxAbsDiff(expected, actual)
                    val tolerance = tolerances[tensorName.substringBefore('_')] ?: tolerances.getValue(tensorName)
                    report.append("$name $tensorName: max abs diff %.3e (tolerance %.1e)\n".format(diff, tolerance))
                    assertTrue(diff <= tolerance, "$name $tensorName: max abs diff $diff > $tolerance")
                }

                // The returned audio is the vocoder output trimmed to the
                // predicted duration.
                val wav = trace.floats.getValue("wav")
                assertTrue(pcm.size <= wav.size && pcm.size > wav.size - model.config.chunkSize)
                val expectedPcm = readFloats(File(root, case["pcm"] as String))
                assertEquals(expectedPcm.size, pcm.size, "$name pcm length")
                val diff = maxAbsDiff(expectedPcm, pcm)
                worstWav = maxOf(worstWav, diff)
                report.append("$name pcm: ${pcm.size} samples, max abs diff %.3e\n".format(diff))
                File(root, "kotlin_$name.f32").writeBytes(
                    ByteBuffer.allocate(pcm.size * 4).order(ByteOrder.LITTLE_ENDIAN)
                        .also { b -> pcm.forEach { b.putFloat(it) } }.array(),
                )
            }
        }
        println(report)
        File(root, "kotlin_report.txt").writeText(report.toString())
        assertTrue(worstWav <= tolerances.getValue("wav"))
    }

    private fun maxAbsDiff(a: FloatArray, b: FloatArray): Double {
        var max = 0.0
        for (i in a.indices) max = maxOf(max, abs(a[i].toDouble() - b[i].toDouble()))
        return max
    }

    private fun readFloats(file: File): FloatArray {
        val buffer = ByteBuffer.wrap(file.readBytes()).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
        return FloatArray(buffer.remaining()).also { buffer.get(it) }
    }

    private fun readLongs(file: File): LongArray {
        val buffer = ByteBuffer.wrap(file.readBytes()).order(ByteOrder.LITTLE_ENDIAN).asLongBuffer()
        return LongArray(buffer.remaining()).also { buffer.get(it) }
    }
}
