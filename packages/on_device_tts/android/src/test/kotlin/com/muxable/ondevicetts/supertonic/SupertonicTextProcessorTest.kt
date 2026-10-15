package com.muxable.ondevicetts.supertonic

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

class SupertonicTextProcessorTest {
    private class Case(val text: String, val lang: String, val expected: String)

    /** Every BMP character is known, as index = code point. */
    private val everything = SupertonicTextProcessor(IntArray(0x10000) { it })

    @Test
    fun `preprocesses like the reference`() {
        // The expected strings come from the `supertonic` 1.3.1 Python
        // package's UnicodeProcessor._preprocess_text.
        val cases = listOf(
            Case("Hello world", "en", "<en>Hello world.</en>"),
            Case("Hello world!", "en", "<en>Hello world!</en>"),
            Case("  lots   of\u0009space\u000a\u000ahere ", "en", "<en>lots of space here.</en>"),
            Case("café crème brûlée", "fr", "<fr>café crème brûlée.</fr>"),
            Case("ﬁne ＡＢＣ ①", "en", "<en>fine ABC 1.</en>"),
            Case("pog 😀🔥 so good ❤️", "en", "<en>pog so good ️.</en>"),
            Case("dash – and — and ‑ hyphen", "en", "<en>dash - and - and ‐ hyphen.</en>"),
            Case("“quoted” and ‘single’ and `tick`", "en", "<en>\"quoted\" and'single' and'tick'</en>"),
            Case("snake_case [x] a|b c/d #tag → ←", "en", "<en>snake case x a b c d tag.</en>"),
            Case("love ♥ star ☆ © back\\slash", "en", "<en>love star backslash.</en>"),
            Case("mail me @ home, e.g., now; i.e., later", "en", "<en>mail me at home, for example, now; that is, later.</en>"),
            Case("spaces , before . marks ! really ? yes ; ok : fine ' end", "en", "<en>spaces, before. marks! really? yes; ok: fine' end.</en>"),
            Case("double \"\"quotes\"\" and ''single''", "en", "<en>double \"quotes\" and'single'</en>"),
            Case("ends with quote »", "en", "<en>ends with quote »</en>"),
            Case("ends with ellipsis…", "en", "<en>ends with ellipsis...</en>"),
            Case("Привет, как дела", "ru", "<ru>Привет, как дела.</ru>"),
            Case("안녕하세요", "ko", "<ko>안녕하세요.</ko>"),
            Case("こんにちは。", "ja", "<ja>こんにちは。</ja>"),
            Case("unknown language text", "na", "<na>unknown language text.</na>"),
            Case("nbsp and em　ideographic", "en", "<en>nbsp and em ideographic.</en>"),
            Case("macron ¯ and acute ´", "en", "<en>macron ̄ and acute ́.</en>"),
        )
        for (case in cases) {
            assertEquals(case.expected, everything.preprocess(case.text, case.lang), "for ${case.text}")
        }
    }

    @Test
    fun `drops characters the model doesn't know`() {
        // Like the real indexer: U+FE0F (the emoji variation selector) and
        // CJK ideographs past the table are unknown.
        val indexer = IntArray(0x10000) { it }
        indexer[0xFE0F] = -1
        val processor = SupertonicTextProcessor(indexer)
        assertEquals("<en>pog so good.</en>", processor.preprocess("pog so good ❤️", "en"))
        assertEquals("<en>a b.</en>", processor.preprocess("a ️️ b", "en"))
        // Supplementary characters are past the end of the table.
        assertEquals("<en>math ok.</en>", processor.preprocess("math 𠀀 ok", "en"))
        assertEquals("<en>.</en>", processor.preprocess("️", "en"))
    }

    @Test
    fun `strips emoji ranges`() {
        assertEquals("ab", SupertonicTextProcessor.removeEmojis("a😀☀➿🇦b"))
        assertEquals("◿⠀", SupertonicTextProcessor.removeEmojis("◿⠀"))
    }

    @Test
    fun `maps code points through the indexer`() {
        val indexer = IntArray(0x10000) { -1 }
        "<en>hi.</>".forEach { indexer[it.code] = it.code + 1000 }
        val processor = SupertonicTextProcessor(indexer)
        val expected = "<en>hi.</en>".map { (it.code + 1000).toLong() }.toLongArray()
        assertContentEquals(expected, processor.encode("hi", "en"))
    }

    @Test
    fun `rejects unknown language tokens`() {
        assertThrows<IllegalArgumentException> { everything.preprocess("hi", "xx") }
    }

    @Test
    fun `resolves BCP-47 tags to language tokens`() {
        assertEquals("en", SupertonicLanguages.resolve("en"))
        assertEquals("en", SupertonicLanguages.resolve("en-US"))
        assertEquals("pt", SupertonicLanguages.resolve("pt_BR"))
        assertEquals("ru", SupertonicLanguages.resolve("RU"))
        assertEquals("na", SupertonicLanguages.resolve("zh-Hans"))
        assertEquals("na", SupertonicLanguages.resolve(""))
        assertEquals("na", SupertonicLanguages.resolve("na"))
        assertEquals(31, SupertonicLanguages.SUPPORTED.size)
    }
}
