/// Splits text into clauses, so a streaming engine can start playing the
/// first clause while it synthesizes the rest.
///
/// Splitting between clauses keeps the prosody natural; splitting inside one
/// doesn't, so [split] only breaks text:
///
/// * after clause punctuation followed by whitespace or the end of the text:
///   `, ; : . ! ?` and `…`, with any closing quotes or brackets after them
///   (`"Wow!" she said` breaks after `"Wow!"`). A run of punctuation such as
///   `!!!`, `?!` or `...` stays together. Punctuation inside a token, as in
///   `3.5`, `1,000`, `10:30` or `example.com`, doesn't break, nor do
///   emoticons such as `:)`.
/// * after CJK, Arabic and Devanagari clause punctuation
///   (`。！？；：，、．` `،؛؟` `।`) even without whitespace, since these
///   scripts don't put spaces between words.
/// * not after common abbreviations (`Mr.`, `Dr.`, `e.g.`, `vs.`) or an
///   initial (`J.`).
///
/// A fragment with fewer than [minLetters] letters and digits (`Hi,`, `lol,`,
/// `GG!`) is too short to say on its own: it joins the next clause, or the
/// previous one when it's the last. A clause longer than [maxLength] UTF-16
/// code units is split at the last whitespace that fits, or, without any,
/// at [maxLength].
class ClauseSplitter {
  /// The longest segment [split] returns, in UTF-16 code units.
  final int maxLength;

  /// The fewest letters and digits a clause needs to be its own segment.
  final int minLetters;

  const ClauseSplitter({this.maxLength = 300, this.minLetters = 6})
      : assert(maxLength > 1),
        assert(minLetters >= 0);

  /// Breaks after these when whitespace or the end of the text follows.
  static const _spacedPunctuation = ',;:.!?…';

  /// Breaks after these even when no whitespace follows.
  static const _unspacedPunctuation = '。！？；：，、．｡､،؛؟।॥';

  /// Closing quotes and brackets that stay with the punctuation before them.
  static const _closers = '"\'”’»)]}）】」』〉》〕';

  /// Words ending in `.` that don't end a sentence, lowercased.
  static const _abbreviations = {
    'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'vs', 'etc', 'e.g', //
    'i.e', 'approx', 'cf', 'mt', 'ft', 'u.s', 'a.m', 'p.m',
  };

  static final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
  static final _whitespace = RegExp(r'\s');

  /// The clauses of [text], trimmed, in order and without empty ones.
  /// Where two fragments were merged, the text between them is kept as it
  /// was.
  List<String> split(String text) => _mergeTiny(_clauses(text).expand(_limit))
      .map((clause) => clause.trim())
      .where((clause) => clause.isNotEmpty)
      .toList();

  /// Splits at every clause boundary.
  List<String> _clauses(String text) {
    final clauses = <String>[];
    var start = 0;
    var i = 0;
    while (i < text.length) {
      final char = text[i];
      final unspaced = _unspacedPunctuation.contains(char);
      if (!unspaced && !_spacedPunctuation.contains(char)) {
        i++;
        continue;
      }
      // An emoticon such as `:)` or `;]` isn't a clause boundary.
      if ((char == ':' || char == ';') &&
          i + 1 < text.length &&
          _closers.contains(text[i + 1])) {
        i += 2;
        continue;
      }
      // The whole run of punctuation and closers goes with this clause.
      var end = i + 1;
      var hasUnspaced = unspaced;
      while (end < text.length &&
          (_spacedPunctuation.contains(text[end]) ||
              _unspacedPunctuation.contains(text[end]) ||
              _closers.contains(text[end]))) {
        if (_unspacedPunctuation.contains(text[end])) hasUnspaced = true;
        end++;
      }
      final atBoundary = end == text.length || _isSpace(text, end);
      if ((hasUnspaced || atBoundary) && !_isAbbreviation(text, start, i)) {
        clauses.add(text.substring(start, end));
        start = end;
      }
      i = end;
    }
    if (start < text.length) clauses.add(text.substring(start));
    return clauses;
  }

  static bool _isSpace(String text, int index) =>
      _whitespace.hasMatch(text[index]);

  /// Whether the `.` at [dot] ends an abbreviation or an initial rather than
  /// a clause. Only a lone `.` can: `Dr..` or `etc.!` end clauses.
  static bool _isAbbreviation(String text, int clauseStart, int dot) {
    if (text[dot] != '.') return false;
    if (dot + 1 < text.length && !_isSpace(text, dot + 1)) return false;
    var wordStart = dot;
    while (wordStart > clauseStart && !_isSpace(text, wordStart - 1)) {
      wordStart--;
    }
    final word = text.substring(wordStart, dot);
    if (word.isEmpty) return false;
    // An initial, as in "J. R. R. Tolkien".
    if (word.length == 1 && word.toUpperCase() != word.toLowerCase()) {
      return word == word.toUpperCase();
    }
    return _abbreviations.contains(word.toLowerCase());
  }

  /// Splits [clause] into pieces of at most [maxLength] code units once
  /// trimmed. The pieces put together give back [clause].
  Iterable<String> _limit(String clause) sync* {
    var rest = clause;
    while (rest.trim().length > maxLength) {
      final lead = rest.length - rest.trimLeft().length;
      final limit = lead + maxLength;
      var cut = rest.lastIndexOf(_whitespace, limit);
      if (cut <= lead) {
        cut = limit;
        // Don't split a surrogate pair.
        if (_isHighSurrogate(rest.codeUnitAt(cut - 1))) cut--;
      }
      yield rest.substring(0, cut);
      rest = rest.substring(cut);
    }
    yield rest;
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  bool _isTiny(String clause) =>
      _letterOrDigit.allMatches(clause).length < minLetters;

  bool _fits(String joined) => joined.trim().length <= maxLength;

  /// Joins clauses too short to say on their own to a neighbour. [clauses]
  /// keep their surrounding whitespace, so joining them is concatenation.
  List<String> _mergeTiny(Iterable<String> clauses) {
    final merged = <String>[];
    String? carry;
    for (final clause in clauses) {
      if (clause.trim().isEmpty) {
        // Keep whitespace with its neighbours.
        if (carry != null) {
          carry += clause;
        } else if (merged.isNotEmpty) {
          merged.last += clause;
        } else {
          carry = clause;
        }
        continue;
      }
      var current = clause;
      if (carry != null) {
        if (_fits(carry + current)) {
          current = carry + current;
        } else {
          merged.add(carry);
        }
        carry = null;
      }
      if (_isTiny(current)) {
        carry = current;
      } else {
        merged.add(current);
      }
    }
    if (carry != null) {
      if (merged.isNotEmpty && _fits(merged.last + carry)) {
        merged.last += carry;
      } else {
        merged.add(carry);
      }
    }
    return merged;
  }
}
