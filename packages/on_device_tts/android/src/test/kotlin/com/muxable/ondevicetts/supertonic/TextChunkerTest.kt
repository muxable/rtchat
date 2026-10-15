package com.muxable.ondevicetts.supertonic

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class TextChunkerTest {
    @Test
    fun `keeps short text whole`() {
        assertEquals(listOf("Hello chat. How are you?"), TextChunker.chunk("  Hello chat. How are you?  "))
    }

    @Test
    fun `makes nothing of blank text`() {
        assertEquals(emptyList(), TextChunker.chunk(""))
        assertEquals(emptyList(), TextChunker.chunk(" \n\n "))
    }

    @Test
    fun `splits paragraphs`() {
        assertEquals(listOf("One.", "Two."), TextChunker.chunk("One.\n\nTwo."))
        assertEquals(listOf("One.", "Two."), TextChunker.chunk("One.\n  \n\nTwo."))
        assertEquals(listOf("One.\nTwo."), TextChunker.chunk("One.\nTwo."))
    }

    @Test
    fun `packs sentences up to the limit`() {
        val sentence = "This sentence is exactly forty chars ok." // 40
        assertEquals(40, sentence.length)
        val text = List(5) { sentence }.joinToString(" ")
        // 40 + 1 + 40 = 81 > 80, so one sentence per chunk.
        assertEquals(List(5) { sentence }, TextChunker.chunk(text, 80))
        // Two fit in 81.
        assertEquals(
            listOf("$sentence $sentence", "$sentence $sentence", sentence),
            TextChunker.chunk(text, 81),
        )
    }

    @Test
    fun `doesn't split after abbreviations`() {
        val text = "Dr. Smith and Mr. Jones met. They talked for a long while about everything."
        assertEquals(
            listOf("Dr. Smith and Mr. Jones met.", "They talked for a long while about everything."),
            TextChunker.chunk(text, 50),
        )
    }

    @Test
    fun `splits long sentences on commas, then spaces`() {
        val text = "first part here, second part here, third part here"
        assertEquals(
            listOf("first part here, second part here", "third part here"),
            TextChunker.chunk(text, 35),
        )
        val words = "aaaa bbbb cccc dddd eeee"
        assertEquals(listOf("aaaa bbbb", "cccc dddd", "eeee"), TextChunker.chunk(words, 10))
    }

    @Test
    fun `chunks stay within the limit`() {
        val text = List(200) { i -> if (i % 7 == 6) "word$i." else "word$i," }.joinToString(" ")
        val chunks = TextChunker.chunk(text, 120)
        assertTrue(chunks.size > 1)
        assertTrue(chunks.all { it.length <= 120 }, chunks.toString())
        val rejoined = chunks.joinToString(" ").replace(",", "").split(" ").filter { it.isNotEmpty() }
        assertEquals(200, rejoined.size)
    }

    @Test
    fun `uses shorter chunks for Korean and Japanese`() {
        assertEquals(120, TextChunker.maxLengthFor("ko"))
        assertEquals(120, TextChunker.maxLengthFor("ja"))
        assertEquals(300, TextChunker.maxLengthFor("en"))
        assertEquals(300, TextChunker.maxLengthFor("na"))
    }
}
