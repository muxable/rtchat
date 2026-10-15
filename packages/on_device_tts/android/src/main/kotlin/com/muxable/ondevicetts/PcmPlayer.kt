package com.muxable.ondevicetts

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.SystemClock

/**
 * Streams one utterance of mono float PCM to an [AudioTrack] as it's
 * synthesized.
 *
 * Speech plays as media without requesting audio focus, like the system TTS
 * through `flutter_tts` does in the app, so it mixes with other audio
 * instead of pausing or ducking it.
 *
 * The playback thread creates the player (while the first segment is still
 * being synthesized), then calls [write], [drain] and [release]; any thread
 * may call [halt] to cut the utterance off.
 */
internal class PcmPlayer(val sampleRate: Int) {
    private val bufferFrames: Int
    private val track: AudioTrack

    @Volatile
    private var halted = false
    private var released = false

    init {
        val minBytes = AudioTrack.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT,
        )
        // At least 100 ms, so a slow device doesn't underrun between writes.
        val bytes = maxOf(minBytes, sampleRate / 10 * BYTES_PER_FRAME)
        bufferFrames = bytes / BYTES_PER_FRAME
        track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            )
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(bytes)
            .build()
        // A streaming track plays as soon as enough audio is written.
        track.play()
    }

    /** Frames written so far. */
    var framesWritten = 0L
        private set

    /**
     * Writes [pcm], blocking while the buffer is full, and calls [onWritten]
     * after each block. Returns false when [halt] cut the utterance off.
     */
    fun write(pcm: FloatArray, onWritten: () -> Unit = {}): Boolean {
        var offset = 0
        while (offset < pcm.size) {
            if (halted) return false
            val count = minOf(WRITE_FRAMES, pcm.size - offset)
            val written = track.write(pcm, offset, count, AudioTrack.WRITE_BLOCKING)
            if (written < 0) throw IllegalStateException("AudioTrack.write failed: $written")
            offset += written
            framesWritten += written
            onWritten()
        }
        return !halted
    }

    /**
     * Waits until the first [frames] frames written have played, going by
     * the playback head. Returns false when [halt] cut the utterance off.
     */
    fun drain(frames: Long): Boolean {
        // The track may not start until its buffer has filled, so push the
        // last audio through with silence that is never waited for.
        if (!write(FloatArray(bufferFrames))) return false
        var last = -1L
        var lastMoved = SystemClock.elapsedRealtime()
        while (!halted) {
            // Unsigned: wraps after 27 hours at 44.1 kHz.
            val played = track.playbackHeadPosition.toLong() and 0xFFFFFFFFL
            if (played >= frames) break
            val now = SystemClock.elapsedRealtime()
            if (played != last) {
                last = played
                lastMoved = now
            } else if (now - lastMoved > STALL_TIMEOUT_MS) {
                // The output stopped consuming audio; don't hang the caller.
                break
            }
            Thread.sleep(POLL_MS)
        }
        return !halted
    }

    /** Stops playback at once and drops whatever is buffered. */
    @Synchronized
    fun halt() {
        halted = true
        if (!released) {
            track.pause()
            track.flush()
        }
    }

    @Synchronized
    fun release() {
        halted = true
        if (!released) {
            released = true
            track.pause()
            track.flush()
            track.release()
        }
    }

    companion object {
        private const val BYTES_PER_FRAME = 4 // mono float
        private const val WRITE_FRAMES = 2048
        private const val POLL_MS = 5L
        private const val STALL_TIMEOUT_MS = 2000L
    }
}
