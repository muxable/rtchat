package com.muxable.ondevicetts.supertonic

import kotlin.math.abs
import kotlin.math.sqrt
import org.junit.jupiter.api.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class NoiseGeneratorTest {
    @Test
    fun `is SplitMix64`() {
        // The published SplitMix64 sequence for seed 0.
        val g = NoiseGenerator(0)
        assertEquals(0xE220A8397B1DCDAFuL.toLong(), g.nextLong())
        assertEquals(0x6E789E6AA1B965F4L, g.nextLong())
        assertEquals(0x06C45D188009454FL, g.nextLong())
    }

    @Test
    fun `matches the documented Box-Muller samples`() {
        // From the contract's Python version of the generator.
        assertContentEquals(
            floatArrayOf(
                0.8822488784790039f, -0.45084986090660095f, 0.18835262954235077f,
                0.21958637237548828f, -0.6703714728355408f, -0.6765279769897461f,
            ),
            NoiseGenerator(42).gaussians(6),
        )
        assertContentEquals(
            floatArrayOf(1.8068959712982178f, -0.6297152638435364f, 0.7070683836936951f),
            NoiseGenerator(-1).gaussians(3),
        )
    }

    @Test
    fun `is deterministic per seed`() {
        assertContentEquals(NoiseGenerator(7).gaussians(100), NoiseGenerator(7).gaussians(100))
        assertTrue(!NoiseGenerator(7).gaussians(100).contentEquals(NoiseGenerator(8).gaussians(100)))
    }

    @Test
    fun `is standard normal`() {
        val samples = NoiseGenerator(1234).gaussians(200_000)
        val mean = samples.average()
        val std = sqrt(samples.sumOf { (it - mean) * (it - mean) } / samples.size)
        assertTrue(abs(mean) < 0.01, "mean $mean")
        assertTrue(abs(std - 1) < 0.01, "std $std")
        assertTrue(samples.all { it.isFinite() })
    }

    @Test
    fun `uniforms are in the unit interval`() {
        val g = NoiseGenerator(99)
        repeat(10_000) {
            val u = g.nextDouble()
            assertTrue(u >= 0.0 && u < 1.0)
        }
    }
}
