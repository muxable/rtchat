// Ported from Supertone's reference code: the `UnicodeProcessor` of the
// `supertonic` Python package (1.3.1) and the Java sample in
// https://github.com/supertone-oss-archive/supertonic, under this license:
//
// MIT License
//
// Copyright (c) 2025 Supertone Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package com.muxable.ondevicetts.supertonic

import java.text.Normalizer

/** The languages Supertonic 3 was trained on, plus `na` for anything else. */
internal object SupertonicLanguages {
    val SUPPORTED = listOf(
        "en", "ko", "ja", "ar", "bg", "cs", "da", "de", "el", "es", "et", "fi", "fr", "hi", "hr",
        "hu", "id", "it", "lt", "lv", "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sv", "tr", "uk", "vi",
    )

    /** The language token for text in an unknown or unsupported language. */
    const val UNKNOWN = "na"

    /**
     * The model's language token for a BCP-47 tag: its primary subtag,
     * lowercased (`pt-BR` → `pt`), or [UNKNOWN] when the model doesn't
     * speak it.
     */
    fun resolve(tag: String): String {
        val primary = tag.trim().lowercase().split('-', '_').first()
        return if (primary in SUPPORTED) primary else UNKNOWN
    }
}

/**
 * Turns text into the model's input: normalizes it the way the reference
 * implementation does, wraps it in language tokens, and maps each code point
 * through `unicode_indexer.json`.
 *
 * One deliberate difference: the reference rejects text with characters the
 * model doesn't know, but chat is full of them, so they are dropped instead
 * (before whitespace is cleaned up). Text made only of known characters
 * comes out exactly as in the reference.
 */
internal class SupertonicTextProcessor(private val indexer: IntArray) {

    /** The model ids of [text], after preprocessing, as a `[1, n]` row. */
    fun encode(text: String, lang: String): LongArray {
        val processed = preprocess(text, lang)
        val codePoints = processed.codePoints().toArray()
        return LongArray(codePoints.size) { i -> indexer[codePoints[i]].toLong() }
    }

    fun isSupported(codePoint: Int): Boolean = codePoint < indexer.size && indexer[codePoint] >= 0

    fun preprocess(text: String, lang: String): String {
        require(lang == SupertonicLanguages.UNKNOWN || lang in SupertonicLanguages.SUPPORTED) {
            "Invalid language: $lang"
        }
        var s = Normalizer.normalize(text, Normalizer.Form.NFKD)
        s = removeEmojis(s)
        for ((from, to) in SYMBOL_REPLACEMENTS) {
            s = s.replace(from, to)
        }
        s = SPECIAL_SYMBOLS.replace(s, "")
        for ((from, to) in EXPRESSION_REPLACEMENTS) {
            s = s.replace(from, to)
        }
        for ((from, to) in PUNCTUATION_SPACING) {
            s = s.replace(from, to)
        }
        s = DUPLICATE_QUOTES.replace(s, "$1")
        s = removeUnsupported(s)
        s = WHITESPACE.replace(s, " ").trim(' ')
        if (!ENDING_PUNCTUATION.containsMatchIn(s)) {
            s += "."
        }
        return "<$lang>$s</$lang>"
    }

    private fun removeUnsupported(text: String): String {
        val sb = StringBuilder(text.length)
        text.codePoints().forEach { cp ->
            // Whitespace is collapsed next, so keep it even if unknown.
            if (isSupported(cp) || SINGLE_WHITESPACE.matches(String(Character.toChars(cp)))) {
                sb.appendCodePoint(cp)
            }
        }
        return sb.toString()
    }

    companion object {
        private val EMOJI_RANGES = arrayOf(
            0x1F600..0x1F64F, // emoticons
            0x1F300..0x1F5FF, // symbols & pictographs
            0x1F680..0x1F6FF, // transport & map symbols
            0x1F700..0x1F77F,
            0x1F780..0x1F7FF,
            0x1F800..0x1F8FF,
            0x1F900..0x1F9FF,
            0x1FA00..0x1FA6F,
            0x1FA70..0x1FAFF,
            0x2600..0x26FF,
            0x2700..0x27BF,
            0x1F1E6..0x1F1FF,
        )

        private val SYMBOL_REPLACEMENTS = listOf(
            "–" to "-", // en dash
            "‑" to "-", // non-breaking hyphen
            "—" to "-", // em dash
            "¯" to " ", // macron
            "_" to " ",
            "“" to "\"", // left double quotation mark
            "”" to "\"", // right double quotation mark
            "‘" to "'", // left single quotation mark
            "’" to "'", // right single quotation mark
            "´" to "'", // acute accent
            "`" to "'",
            "[" to " ",
            "]" to " ",
            "|" to " ",
            "/" to " ",
            "#" to " ",
            "→" to " ", // →
            "←" to " ", // ←
        )

        private val SPECIAL_SYMBOLS = Regex("[♥☆♡©\\\\]")

        private val EXPRESSION_REPLACEMENTS = listOf(
            "@" to " at ",
            "e.g.," to "for example, ",
            "i.e.," to "that is, ",
        )

        private val PUNCTUATION_SPACING = listOf(
            " ," to ",",
            " ." to ".",
            " !" to "!",
            " ?" to "?",
            " ;" to ";",
            " :" to ":",
            " '" to "'",
        )

        private val DUPLICATE_QUOTES = Regex("([\"'`])\\1+")

        // Python's `\s` on str: every character for which str.isspace() is
        // true. Java's `\s` only covers ASCII.
        private const val WHITESPACE_CLASS =
            "[\\t\\n\\x0B\\f\\r\\x1C-\\x1F \\x85\\xA0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000]"
        private val WHITESPACE = Regex("$WHITESPACE_CLASS+")
        private val SINGLE_WHITESPACE = Regex(WHITESPACE_CLASS)

        private val ENDING_PUNCTUATION =
            Regex("[.!?;:,'\"')\\]}…。」』】〉》›»]$")

        fun removeEmojis(text: String): String {
            val sb = StringBuilder(text.length)
            text.codePoints().forEach { cp ->
                if (EMOJI_RANGES.none { cp in it }) sb.appendCodePoint(cp)
            }
            return sb.toString()
        }
    }
}
