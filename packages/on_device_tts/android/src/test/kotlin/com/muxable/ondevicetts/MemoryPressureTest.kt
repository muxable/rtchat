package com.muxable.ondevicetts

import android.content.ComponentCallbacks2
import com.muxable.ondevicetts.MemoryPressure.LOW_MEMORY
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_BACKGROUND
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_COMPLETE
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_MODERATE
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_RUNNING_CRITICAL
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_RUNNING_LOW
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_RUNNING_MODERATE
import com.muxable.ondevicetts.MemoryPressure.TRIM_MEMORY_UI_HIDDEN
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MemoryPressureTest {
    @Test
    fun `going to the background and mild levels don't release`() {
        // Flutter reports UI_HIDDEN as memory pressure; a pocketed phone with
        // TTS on must keep its model.
        for (level in listOf(TRIM_MEMORY_UI_HIDDEN, TRIM_MEMORY_RUNNING_MODERATE, TRIM_MEMORY_RUNNING_LOW)) {
            assertFalse(MemoryPressure.shouldRelease(level), "level $level")
        }
    }

    @Test
    fun `critical and cached levels release`() {
        for (level in listOf(TRIM_MEMORY_RUNNING_CRITICAL, TRIM_MEMORY_BACKGROUND, TRIM_MEMORY_MODERATE, LOW_MEMORY)) {
            assertTrue(MemoryPressure.shouldRelease(level), "level $level")
        }
    }

    @Test
    @Suppress("DEPRECATION")
    fun `constants match android's`() {
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE, TRIM_MEMORY_RUNNING_MODERATE)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW, TRIM_MEMORY_RUNNING_LOW)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, TRIM_MEMORY_RUNNING_CRITICAL)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN, TRIM_MEMORY_UI_HIDDEN)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_BACKGROUND, TRIM_MEMORY_BACKGROUND)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_MODERATE, TRIM_MEMORY_MODERATE)
        assertEquals(ComponentCallbacks2.TRIM_MEMORY_COMPLETE, TRIM_MEMORY_COMPLETE)
    }
}
