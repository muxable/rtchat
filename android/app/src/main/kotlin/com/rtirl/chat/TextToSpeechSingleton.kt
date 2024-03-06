package com.rtirl.chat

import android.content.Context
import android.speech.tts.TextToSpeech

object TextToSpeechSingleton {
    private var tts: TextToSpeech? = null

    fun getInstance(context: Context): TextToSpeech {
        if (tts == null) {
            tts = TextToSpeech(context.applicationContext) { status ->
                if (status != TextToSpeech.SUCCESS) {
                    // Handle initialization error
                }
            }
        }
        return tts!!
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }
}
