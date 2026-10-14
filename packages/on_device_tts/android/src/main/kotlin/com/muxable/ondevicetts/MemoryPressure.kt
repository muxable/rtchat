package com.muxable.ondevicetts

/**
 * Which of Android's memory signals should unload the models.
 *
 * Flutter forwards every `onTrimMemory` from `TRIM_MEMORY_RUNNING_LOW` up to
 * Dart as `didHaveMemoryPressure`, and that includes `TRIM_MEMORY_UI_HIDDEN`,
 * which only means the app went to the background. A streamer pockets the
 * phone with TTS on, so releasing on that would unload the model every time
 * and reload it for the next message. The plugin instead forwards only the
 * levels that mean memory is actually short, on `on_device_tts/memory`.
 */
internal object MemoryPressure {
    // The ComponentCallbacks2 constants, so JVM tests don't need android.jar.
    const val TRIM_MEMORY_RUNNING_MODERATE = 5
    const val TRIM_MEMORY_RUNNING_LOW = 10
    const val TRIM_MEMORY_RUNNING_CRITICAL = 15
    const val TRIM_MEMORY_UI_HIDDEN = 20
    const val TRIM_MEMORY_BACKGROUND = 40
    const val TRIM_MEMORY_MODERATE = 60
    const val TRIM_MEMORY_COMPLETE = 80

    /** The level reported for `onLowMemory`. */
    const val LOW_MEMORY = TRIM_MEMORY_COMPLETE

    /**
     * Whether a trim [level] should release the models:
     *
     * * `RUNNING_CRITICAL`: the system is about to kill background processes
     *   and may kill ours next. (Android 14 and later no longer send the
     *   `RUNNING_*` levels; `onLowMemory` still comes.)
     * * `BACKGROUND` and above: the process is in the cached LRU list, i.e.
     *   TTS is off or its foreground service isn't running, so nothing is
     *   being read and a few hundred megabytes of model only make the process
     *   the first to be killed.
     *
     * Not `UI_HIDDEN`, `RUNNING_MODERATE` or `RUNNING_LOW`.
     */
    fun shouldRelease(level: Int): Boolean =
        level == TRIM_MEMORY_RUNNING_CRITICAL || level >= TRIM_MEMORY_BACKGROUND
}
