package com.muxable.ondevicetts.supertonic

import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

class JsonTest {
    @Test
    fun `parses values`() {
        assertEquals(
            mapOf(
                "a" to listOf(1L, -2L, 3.5, -1.0e-3, 2E2),
                "b" to mapOf("c" to "d\"\\/\né"),
                "t" to true,
                "f" to false,
                "n" to null,
                "e" to listOf<Any?>(),
                "o" to mapOf<String, Any?>(),
            ),
            Json.parse(
                """ { "a": [1, -2, 3.5, -1.0e-3, 2E2], "b": {"c": "d\"\\\/\né"},
                "t": true, "f": false, "n": null, "e": [ ], "o": { } } """,
            ),
        )
    }

    @Test
    fun `rejects malformed JSON`() {
        for (bad in listOf("", "[1,", "{\"a\" 1}", "[1] x", "tru", "\"open", "[1 2]")) {
            assertThrows<IllegalArgumentException>(bad) { Json.parse(bad) }
        }
    }

    @Test
    fun `reads the model config`() {
        val config = SupertonicConfig.parse(
            """{"ae": {"sample_rate": 44100, "base_chunk_size": 512},
                "ttl": {"latent_dim": 24, "chunk_compress_factor": 6, "other": [1]}}""",
        )
        assertEquals(44100, config.sampleRate)
        assertEquals(3072, config.chunkSize)
        assertEquals(144, config.latentChannels)
    }

    @Test
    fun `reads voice styles`() {
        val style = VoiceStyle.parse(
            "F1",
            """{"style_ttl": {"data": [[[1, 2], [3, 4]]], "dims": [1, 2, 2], "type": "float32"},
                "style_dp": {"data": [[[0.5]]], "dims": [1, 1, 1]}, "metadata": {}}""",
        )
        assertContentEquals(floatArrayOf(1f, 2f, 3f, 4f), style.ttl)
        assertContentEquals(longArrayOf(1, 2, 2), style.ttlShape)
        assertContentEquals(floatArrayOf(0.5f), style.dp)
        assertThrows<IllegalArgumentException> {
            VoiceStyle.parse("bad", """{"style_ttl": {"data": [1], "dims": [2]}, "style_dp": {"data": [1], "dims": [1]}}""")
        }
    }
}
