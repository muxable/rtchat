package com.muxable.ondevicetts.supertonic

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.sqrt

/**
 * The Gaussian noise that flow matching starts from, made by a small PRNG
 * that is simple to reimplement, so every platform turns the same seed into
 * the same noise (see `doc/native_contract.md`):
 *
 * * SplitMix64 makes 64-bit words: `state += 0x9E3779B97F4A7C15`, then
 *   `z = state; z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
 *   z = (z ^ (z >>> 27)) * 0x94D049BB133111EB; return z ^ (z >>> 31)`,
 *   all modulo 2^64. The initial state is the seed.
 * * A uniform double in [0, 1) is `(word >>> 11) * 2^-53`.
 * * Each normal sample takes two uniforms, `u1` then `u2`, and is
 *   `sqrt(-2 * ln(1 - u1)) * cos(2 * PI * u2)` in double precision, then
 *   rounded to float.
 * * The `[channels, frames]` latent is filled in row-major order: every frame
 *   of channel 0, then channel 1, and so on.
 */
class NoiseGenerator(seed: Long) {
    private var state: Long = seed

    fun nextLong(): Long {
        state += GOLDEN_GAMMA
        var z = state
        z = (z xor (z ushr 30)) * MIX1
        z = (z xor (z ushr 27)) * MIX2
        return z xor (z ushr 31)
    }

    fun nextDouble(): Double = (nextLong() ushr 11).toDouble() * DOUBLE_UNIT

    fun nextGaussian(): Float {
        val u1 = nextDouble()
        val u2 = nextDouble()
        return (sqrt(-2.0 * ln(1.0 - u1)) * cos(2.0 * PI * u2)).toFloat()
    }

    /** [count] samples, in order. */
    fun gaussians(count: Int): FloatArray = FloatArray(count) { nextGaussian() }

    companion object {
        private const val GOLDEN_GAMMA = -0x61c8864680b583ebL // 0x9E3779B97F4A7C15
        private const val MIX1 = -0x40a7b892e31b1a47L // 0xBF58476D1CE4E5B9
        private const val MIX2 = -0x6b2fb644ecceee15L // 0x94D049BB133111EB
        private const val DOUBLE_UNIT = 1.0 / (1L shl 53)
    }
}
