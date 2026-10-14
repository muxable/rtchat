package com.muxable.ondevicetts

/**
 * Keeps the CPU awake while the engine works: loading a model or speaking an
 * utterance. With the screen off, the app's foreground service keeps the
 * process alive but doesn't keep the CPU running. While audio plays, the
 * audio server holds a wake lock; not while the model (re)loads or the first
 * clause is synthesized, which could then stall until something else wakes
 * the device.
 *
 * Counts holds: [acquire] runs for each new [hold] (with [timeoutMs], so a
 * stuck utterance can't keep the CPU awake for good; acquiring again re-arms
 * the timeout), and [release] runs once the last hold is closed. Thread safe.
 */
internal class ActivityLock(
    private val timeoutMs: Long,
    private val acquire: (timeoutMs: Long) -> Unit,
    private val release: () -> Unit,
) {
    private var holds = 0

    /** Holds the lock until the returned hold is closed; closing twice is harmless. */
    @Synchronized
    fun hold(): AutoCloseable {
        holds++
        acquire(timeoutMs)
        var closed = false
        return AutoCloseable {
            synchronized(this) {
                if (!closed) {
                    closed = true
                    holds--
                    if (holds == 0) release()
                }
            }
        }
    }

    /** The holds not closed yet. */
    val activeHolds: Int
        @Synchronized get() = holds

    companion object {
        /** Longer than any utterance; only reached if one gets stuck. */
        const val DEFAULT_TIMEOUT_MS = 10 * 60 * 1000L
    }
}
