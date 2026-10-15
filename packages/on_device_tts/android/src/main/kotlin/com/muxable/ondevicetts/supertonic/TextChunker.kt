// Ported from `Helper.chunkText` in Supertone's Java sample
// (https://github.com/supertone-oss-archive/supertonic), under this license:
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

import java.util.regex.Pattern

/**
 * Splits long text into chunks the model can synthesize in one pass, on
 * paragraph and sentence boundaries, then on commas and spaces for
 * sentences that are still too long. Chat messages are almost always a
 * single chunk.
 */
internal object TextChunker {
    /** The reference's limit, in UTF-16 units. */
    const val MAX_CHUNK_LENGTH = 300

    /** The reference's shorter limit for Korean and Japanese. */
    const val MAX_CHUNK_LENGTH_CJK = 120

    private val ABBREVIATIONS = arrayOf(
        "Dr.", "Mr.", "Mrs.", "Ms.", "Prof.", "Sr.", "Jr.",
        "St.", "Ave.", "Rd.", "Blvd.", "Dept.", "Inc.", "Ltd.",
        "Co.", "Corp.", "etc.", "vs.", "i.e.", "e.g.", "Ph.D.",
    )

    private val PARAGRAPHS = Regex("\\n\\s*\\n")

    private val SENTENCE_END = Regex(
        "(?<!(?:" + ABBREVIATIONS.joinToString("|") { Pattern.quote(it) } + "))(?<=[.!?])\\s+",
    )

    private val SPACES = Regex("\\s+")

    /** The chunk length limit for a language token. */
    fun maxLengthFor(lang: String): Int =
        if (lang == "ko" || lang == "ja") MAX_CHUNK_LENGTH_CJK else MAX_CHUNK_LENGTH

    /** The chunks of [text]; empty when [text] is blank. */
    fun chunk(text: String, maxLen: Int = MAX_CHUNK_LENGTH): List<String> {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return emptyList()

        val chunks = ArrayList<String>()
        for (rawParagraph in trimmed.split(PARAGRAPHS)) {
            val paragraph = rawParagraph.trim()
            if (paragraph.isEmpty()) continue
            if (paragraph.length <= maxLen) {
                chunks.add(paragraph)
                continue
            }

            val current = StringBuilder()
            var currentLen = 0
            for (rawSentence in paragraph.split(SENTENCE_END)) {
                val sentence = rawSentence.trim()
                if (sentence.isEmpty()) continue

                val sentenceLen = sentence.length
                if (sentenceLen > maxLen) {
                    // Too long on its own: split by comma, then by space.
                    if (current.isNotEmpty()) {
                        chunks.add(current.toString().trim())
                        current.setLength(0)
                        currentLen = 0
                    }
                    for (rawPart in sentence.split(",")) {
                        val part = rawPart.trim()
                        if (part.isEmpty()) continue
                        val partLen = part.length
                        if (partLen > maxLen) {
                            val wordChunk = StringBuilder()
                            var wordChunkLen = 0
                            for (word in part.split(SPACES)) {
                                val wordLen = word.length
                                if (wordChunkLen + wordLen + 1 > maxLen && wordChunk.isNotEmpty()) {
                                    chunks.add(wordChunk.toString().trim())
                                    wordChunk.setLength(0)
                                    wordChunkLen = 0
                                }
                                if (wordChunk.isNotEmpty()) {
                                    wordChunk.append(" ")
                                    wordChunkLen++
                                }
                                wordChunk.append(word)
                                wordChunkLen += wordLen
                            }
                            if (wordChunk.isNotEmpty()) {
                                chunks.add(wordChunk.toString().trim())
                            }
                        } else {
                            if (currentLen + partLen + 1 > maxLen && current.isNotEmpty()) {
                                chunks.add(current.toString().trim())
                                current.setLength(0)
                                currentLen = 0
                            }
                            if (current.isNotEmpty()) {
                                current.append(", ")
                                currentLen += 2
                            }
                            current.append(part)
                            currentLen += partLen
                        }
                    }
                    continue
                }

                if (currentLen + sentenceLen + 1 > maxLen && current.isNotEmpty()) {
                    chunks.add(current.toString().trim())
                    current.setLength(0)
                    currentLen = 0
                }
                if (current.isNotEmpty()) {
                    current.append(" ")
                    currentLen++
                }
                current.append(sentence)
                currentLen += sentenceLen
            }
            if (current.isNotEmpty()) {
                chunks.add(current.toString().trim())
            }
        }
        return chunks
    }
}
