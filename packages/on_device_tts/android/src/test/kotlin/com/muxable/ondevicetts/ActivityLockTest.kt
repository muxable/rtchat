package com.muxable.ondevicetts

import kotlin.test.Test
import kotlin.test.assertEquals

class ActivityLockTest {
    private val acquired = mutableListOf<Long>()
    private var released = 0
    private val lock = ActivityLock(1234, { acquired.add(it) }, { released++ })

    @Test
    fun `acquires with the timeout and releases when the hold closes`() {
        val hold = lock.hold()
        assertEquals(listOf(1234L), acquired)
        assertEquals(0, released)
        assertEquals(1, lock.activeHolds)

        hold.close()
        assertEquals(1, released)
        assertEquals(0, lock.activeHolds)
    }

    @Test
    fun `releases only once the last of overlapping holds closes`() {
        // e.g. a model loading while an utterance plays.
        val load = lock.hold()
        val speak = lock.hold()
        assertEquals(2, acquired.size, "each hold re-arms the timeout")

        load.close()
        assertEquals(0, released)
        speak.close()
        assertEquals(1, released)
    }

    @Test
    fun `closing a hold twice releases once`() {
        val first = lock.hold()
        val second = lock.hold()
        first.close()
        first.close()
        assertEquals(0, released)
        assertEquals(1, lock.activeHolds)
        second.close()
        assertEquals(1, released)
    }

    @Test
    fun `acquires again after being released`() {
        lock.hold().close()
        lock.hold().close()
        assertEquals(2, acquired.size)
        assertEquals(2, released)
    }

    @Test
    fun `holds from many threads balance out`() {
        val threads = (1..8).map {
            Thread { repeat(1000) { lock.hold().close() } }
        }
        threads.forEach { it.start() }
        threads.forEach { it.join() }
        assertEquals(0, lock.activeHolds)
        assertEquals(8000, acquired.size)
    }
}
