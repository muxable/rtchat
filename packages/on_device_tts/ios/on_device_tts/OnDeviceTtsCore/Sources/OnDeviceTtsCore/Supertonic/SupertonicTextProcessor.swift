// Ported from Supertone's Supertonic reference code: the text processing of
// the `supertonic` Python package 1.3.1 (supertonic/core.py) and the
// `chunkText` of the Java and Swift samples in
// https://github.com/supertone-oss-archive/supertonic.
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

import Foundation

/// Turns text into Supertonic 3's input: NFKD-normalized, cleaned up and
/// wrapped in language tokens, then mapped to ids with `unicode_indexer.json`.
public final class SupertonicTextProcessor {
  /// The languages Supertonic 3 was trained on, plus `na` for text in any
  /// other language.
  public static let languages: [String] = [
    "en", "ko", "ja", "ar", "bg", "cs", "da", "de", "el", "es", "et", "fi", "fr", "hi", "hr",
    "hu", "id", "it", "lt", "lv", "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sv", "tr", "uk",
    "vi", "na",
  ]

  /// The language code for text in a language Supertonic doesn't know.
  public static let unknownLanguage = "na"

  private let indexer: [Int64]

  public init(indexer: [Int64]) {
    self.indexer = indexer
  }

  public convenience init(indexerURL: URL) throws {
    let data = try Data(contentsOf: indexerURL)
    let indexer = try JSONDecoder().decode([Int64].self, from: data)
    if indexer.isEmpty {
      throw SupertonicError.invalidModel("unicode_indexer.json is empty")
    }
    self.init(indexer: indexer)
  }

  /// Maps a BCP-47 tag such as `pt-BR` to one of [languages]: its primary
  /// subtag when Supertonic knows it, otherwise `na`.
  public static func resolveLanguage(_ tag: String?) -> String {
    guard let tag = tag, !tag.isEmpty else { return unknownLanguage }
    let primary = tag.lowercased()
      .split(whereSeparator: { $0 == "-" || $0 == "_" })
      .first.map(String.init) ?? ""
    return languages.contains(primary) ? primary : unknownLanguage
  }

  /// Whether the model has an embedding for `scalar`.
  public func supports(_ scalar: Unicode.Scalar) -> Bool {
    let value = Int(scalar.value)
    return value < indexer.count && indexer[value] >= 0
  }

  /// The model's input ids for `text` in `language` (one of [languages]).
  ///
  /// Unlike the reference, which rejects text with characters the model
  /// can't read, this drops those characters (keeping whitespace): chat is
  /// full of them.
  public func encode(_ text: String, language: String) -> [Int64] {
    let processed = SupertonicTextProcessor.preprocess(
      text, language: language, keep: { self.supports($0) })
    return processed.unicodeScalars.map { scalar in
      let value = Int(scalar.value)
      return value < indexer.count ? indexer[value] : -1
    }
  }

  // MARK: - Preprocessing (supertonic/core.py `UnicodeProcessor._preprocess_text`)

  private static let symbolReplacements: [(String, String)] = [
    ("\u{2013}", "-"),  // en dash
    ("\u{2011}", "-"),  // non-breaking hyphen
    ("\u{2014}", "-"),  // em dash
    ("\u{00AF}", " "),  // macron
    ("_", " "),
    ("\u{201C}", "\""),
    ("\u{201D}", "\""),
    ("\u{2018}", "'"),
    ("\u{2019}", "'"),
    ("\u{00B4}", "'"),  // acute accent
    ("`", "'"),
    ("[", " "),
    ("]", " "),
    ("|", " "),
    ("/", " "),
    ("#", " "),
    ("\u{2192}", " "),  // →
    ("\u{2190}", " "),  // ←
  ]

  private static let specialSymbols: Set<Unicode.Scalar> = ["♥", "☆", "♡", "©", "\\"]

  private static let expressionReplacements: [(String, String)] = [
    ("@", " at "),
    ("e.g.,", "for example, "),
    ("i.e.,", "that is, "),
  ]

  private static let punctuationSpacing: [(String, String)] = [
    (" ,", ","),
    (" .", "."),
    (" !", "!"),
    (" ?", "?"),
    (" ;", ";"),
    (" :", ":"),
    (" '", "'"),
  ]

  private static let endingPunctuation: Set<Unicode.Scalar> = [
    ".", "!", "?", ";", ":", ",", "'", "\"", ")", "]", "}", "…", "。", "」", "』", "】",
    "〉", "》", "›", "»",
  ]

  private static let duplicateQuotes = try! NSRegularExpression(pattern: "([\"'`])\\1+")

  /// Python's `str.isspace()`, which the reference's `\s` matches.
  static func isPythonSpace(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x09...0x0D, 0x1C...0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A, 0x2028, 0x2029, 0x202F,
      0x205F, 0x3000:
      return true
    default:
      return false
    }
  }

  static func isEmoji(_ value: UInt32) -> Bool {
    switch value {
    case 0x1F600...0x1F64F, 0x1F300...0x1F5FF, 0x1F680...0x1F6FF, 0x1F700...0x1F77F,
      0x1F780...0x1F7FF, 0x1F800...0x1F8FF, 0x1F900...0x1F9FF, 0x1FA00...0x1FA6F,
      0x1FA70...0x1FAFF, 0x2600...0x26FF, 0x2700...0x27BF, 0x1F1E6...0x1F1FF:
      return true
    default:
      return false
    }
  }

  private static func filter(_ text: String, _ keep: (Unicode.Scalar) -> Bool) -> String {
    var scalars = String.UnicodeScalarView()
    scalars.append(contentsOf: text.unicodeScalars.filter(keep))
    return String(scalars)
  }

  /// Normalizes `text` the way the reference does and wraps it in
  /// `<language>…</language>`. Characters other than whitespace for which
  /// `keep` returns false are dropped right before whitespace is collapsed.
  public static func preprocess(
    _ text: String, language: String, keep: (Unicode.Scalar) -> Bool = { _ in true }
  ) -> String {
    var text = filter(text.decomposedStringWithCompatibilityMapping) { !isEmoji($0.value) }
    for (old, new) in symbolReplacements {
      text = text.replacingOccurrences(of: old, with: new, options: .literal)
    }
    text = filter(text) { !specialSymbols.contains($0) }
    for (old, new) in expressionReplacements {
      text = text.replacingOccurrences(of: old, with: new, options: .literal)
    }
    for (old, new) in punctuationSpacing {
      text = text.replacingOccurrences(of: old, with: new, options: .literal)
    }
    text = duplicateQuotes.stringByReplacingMatches(
      in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "$1")
    text = filter(text) { isPythonSpace($0) || keep($0) }

    // Collapse whitespace runs into one space, and trim.
    var collapsed = String.UnicodeScalarView()
    var pendingSpace = false
    for scalar in text.unicodeScalars {
      if isPythonSpace(scalar) {
        pendingSpace = true
        continue
      }
      if pendingSpace && !collapsed.isEmpty { collapsed.append(" ") }
      pendingSpace = false
      collapsed.append(scalar)
    }
    text = String(collapsed)

    if let last = text.unicodeScalars.last, endingPunctuation.contains(last) {
      // Already ends a sentence.
    } else {
      text += "."
    }
    return "<\(language)>\(text)</\(language)>"
  }

  // MARK: - Chunking (`chunkText` in the Java sample)

  /// Java's `\s`, which the sample's regular expressions use.
  private static let javaSpace = "[ \\t\\n\\x0B\\f\\r]"
  private static let abbreviations = [
    "Dr.", "Mr.", "Mrs.", "Ms.", "Prof.", "Sr.", "Jr.", "St.", "Ave.", "Rd.", "Blvd.", "Dept.",
    "Inc.", "Ltd.", "Co.", "Corp.", "etc.", "vs.", "i.e.", "e.g.", "Ph.D.",
  ]
  private static let paragraphSeparator = try! NSRegularExpression(
    pattern: "\\n\(javaSpace)*\\n")
  private static let sentenceSeparator = try! NSRegularExpression(
    pattern: "(?<!(?:"
      + abbreviations.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
      + "))(?<=[.!?])\(javaSpace)+")
  private static let spaces = try! NSRegularExpression(pattern: "\(javaSpace)+")

  /// The chunk length limit for a language: 120 for Korean and Japanese,
  /// 300 otherwise.
  public static func maxChunkLength(language: String) -> Int {
    language == "ko" || language == "ja" ? 120 : 300
  }

  private static func split(_ text: String, by regex: NSRegularExpression) -> [String] {
    let ns = text as NSString
    var parts = [String]()
    var start = 0
    for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
      parts.append(ns.substring(with: NSRange(location: start, length: match.range.location - start)))
      start = match.range.location + match.range.length
    }
    parts.append(ns.substring(from: start))
    return parts
  }

  /// Kotlin's and Java's `trim()`: drops characters up to U+0020 at both ends.
  private static func trim(_ text: String) -> String {
    var scalars = Substring(text).unicodeScalars
    while let first = scalars.first, first.value <= 0x20 { scalars.removeFirst() }
    while let last = scalars.last, last.value <= 0x20 { scalars.removeLast() }
    return String(scalars)
  }

  /// Lengths are in UTF-16 units, as in the sample.
  private static func length(_ text: String) -> Int { text.utf16.count }

  /// Splits `text` into chunks of at most `maxLength` UTF-16 units: whole
  /// paragraphs when they fit, otherwise sentences packed together, and
  /// sentences that are still too long split at commas, then spaces.
  /// Empty when `text` is blank.
  public static func chunk(_ text: String, maxLength: Int = 300) -> [String] {
    let text = trim(text)
    if text.isEmpty { return [] }
    var chunks = [String]()
    for rawParagraph in split(text, by: paragraphSeparator) {
      let paragraph = trim(rawParagraph)
      if paragraph.isEmpty { continue }
      if length(paragraph) <= maxLength {
        chunks.append(paragraph)
        continue
      }
      var current = ""
      var currentLength = 0
      func flush() {
        if !current.isEmpty { chunks.append(trim(current)) }
        current = ""
        currentLength = 0
      }
      for rawSentence in split(paragraph, by: sentenceSeparator) {
        let sentence = trim(rawSentence)
        if sentence.isEmpty { continue }
        let sentenceLength = length(sentence)
        if sentenceLength > maxLength {
          // Too long on its own: split by comma, then by space.
          flush()
          for rawPart in sentence.components(separatedBy: ",") {
            let part = trim(rawPart)
            if part.isEmpty { continue }
            let partLength = length(part)
            if partLength > maxLength {
              var words = ""
              var wordsLength = 0
              for word in split(part, by: spaces) {
                let wordLength = length(word)
                if wordsLength + wordLength + 1 > maxLength && !words.isEmpty {
                  chunks.append(trim(words))
                  words = ""
                  wordsLength = 0
                }
                if !words.isEmpty {
                  words += " "
                  wordsLength += 1
                }
                words += word
                wordsLength += wordLength
              }
              if !words.isEmpty { chunks.append(trim(words)) }
            } else {
              if currentLength + partLength + 1 > maxLength && !current.isEmpty { flush() }
              if !current.isEmpty {
                current += ", "
                currentLength += 2
              }
              current += part
              currentLength += partLength
            }
          }
          continue
        }
        if currentLength + sentenceLength + 1 > maxLength && !current.isEmpty { flush() }
        if !current.isEmpty {
          current += " "
          currentLength += 1
        }
        current += sentence
        currentLength += sentenceLength
      }
      flush()
    }
    return chunks
  }
}
