package com.muxable.ondevicetts.supertonic

/**
 * A small JSON reader for the model's own files (`tts.json`,
 * `unicode_indexer.json` and the voice styles).
 *
 * `org.json` is only a stub in JVM unit tests, so the pipeline parses with
 * this instead. Objects become [Map]s, arrays [List]s, numbers [Double]s
 * (or [Long]s when they're integers), and `true`/`false`/`null` themselves.
 */
internal class Json private constructor(private val text: String) {
    private var pos = 0

    companion object {
        fun parse(text: String): Any? {
            val json = Json(text)
            json.skipWhitespace()
            val value = json.readValue()
            json.skipWhitespace()
            if (json.pos != text.length) json.fail("trailing characters")
            return value
        }
    }

    private fun readValue(): Any? {
        skipWhitespace()
        if (pos >= text.length) fail("unexpected end")
        return when (val c = text[pos]) {
            '{' -> readObject()
            '[' -> readArray()
            '"' -> readString()
            't' -> readLiteral("true", true)
            'f' -> readLiteral("false", false)
            'n' -> readLiteral("null", null)
            else -> if (c == '-' || c in '0'..'9') readNumber() else fail("unexpected '$c'")
        }
    }

    private fun readObject(): Map<String, Any?> {
        val result = LinkedHashMap<String, Any?>()
        pos++ // {
        skipWhitespace()
        if (peek() == '}') {
            pos++
            return result
        }
        while (true) {
            skipWhitespace()
            if (peek() != '"') fail("expected a key")
            val key = readString()
            skipWhitespace()
            expect(':')
            result[key] = readValue()
            skipWhitespace()
            when (peek()) {
                ',' -> pos++
                '}' -> {
                    pos++
                    return result
                }
                else -> fail("expected ',' or '}'")
            }
        }
    }

    private fun readArray(): List<Any?> {
        val result = ArrayList<Any?>()
        pos++ // [
        skipWhitespace()
        if (peek() == ']') {
            pos++
            return result
        }
        while (true) {
            result.add(readValue())
            skipWhitespace()
            when (peek()) {
                ',' -> pos++
                ']' -> {
                    pos++
                    return result
                }
                else -> fail("expected ',' or ']'")
            }
        }
    }

    private fun readString(): String {
        pos++ // "
        val sb = StringBuilder()
        while (true) {
            if (pos >= text.length) fail("unterminated string")
            val c = text[pos++]
            when (c) {
                '"' -> return sb.toString()
                '\\' -> {
                    if (pos >= text.length) fail("unterminated escape")
                    when (val e = text[pos++]) {
                        '"', '\\', '/' -> sb.append(e)
                        'b' -> sb.append('\b')
                        'f' -> sb.append('\u000C')
                        'n' -> sb.append('\n')
                        'r' -> sb.append('\r')
                        't' -> sb.append('\t')
                        'u' -> {
                            if (pos + 4 > text.length) fail("bad unicode escape")
                            sb.append(text.substring(pos, pos + 4).toInt(16).toChar())
                            pos += 4
                        }
                        else -> fail("bad escape '\\$e'")
                    }
                }
                else -> sb.append(c)
            }
        }
    }

    private fun readNumber(): Any {
        val start = pos
        var integer = true
        if (peek() == '-') pos++
        while (pos < text.length) {
            val c = text[pos]
            if (c in '0'..'9') {
                pos++
            } else if (c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-') {
                integer = false
                pos++
            } else {
                break
            }
        }
        val s = text.substring(start, pos)
        return try {
            if (integer) s.toLong() else s.toDouble()
        } catch (e: NumberFormatException) {
            fail("bad number '$s'")
        }
    }

    private fun readLiteral(word: String, value: Any?): Any? {
        if (!text.startsWith(word, pos)) fail("unexpected token")
        pos += word.length
        return value
    }

    private fun skipWhitespace() {
        while (pos < text.length && text[pos].let { it == ' ' || it == '\n' || it == '\r' || it == '\t' }) {
            pos++
        }
    }

    private fun peek(): Char = if (pos < text.length) text[pos] else fail("unexpected end")

    private fun expect(c: Char) {
        if (peek() != c) fail("expected '$c'")
        pos++
    }

    private fun fail(message: String): Nothing =
        throw IllegalArgumentException("Invalid JSON at offset $pos: $message")
}
