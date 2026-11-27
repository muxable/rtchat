// The native players can start a phrase while the model synthesizes the next.
// Keep punctuation with its text and leave long individual tokens intact.
final _tokens = RegExp(r'[^\s。！？、，；：]+(?:[。！？、，；：]+[」』”’]*)?|[。！？、，；：]+');
final _closingQuotes = RegExp(r'''["'”’»」』)\]]+$''');
final _punctuation = RegExp(r'[,;:!?.。！？、，；：]$');
final _abbreviation = RegExp(
  r'^(?:[a-z]\.)+$|^(?:dr|mr|mrs|ms|prof|sr|jr|st|ave|rd|blvd|dept|inc|ltd|co|corp|etc|vs|ph\.d)\.$',
  caseSensitive: false,
);

List<String> playbackPhrases(String text, String language) {
  final tag = language.toLowerCase().split(RegExp('[-_]')).first;
  final compact = tag == 'ja' || tag == 'zh' || tag == 'ko';
  final chunks = <String>[];
  int? start;
  var previousEnd = 0;
  for (final token in _tokens.allMatches(text)) {
    final limit = chunks.isEmpty ? (compact ? 28 : 56) : (compact ? 50 : 96);
    if (start != null &&
        (token.end - start > limit ||
            text.substring(previousEnd, token.start).contains('\n'))) {
      chunks.add(text.substring(start, previousEnd));
      start = null;
    }
    start ??= token.start;
    previousEnd = token.end;
    final word = token[0]!.replaceFirst(_closingQuotes, '');
    final minLength = chunks.isEmpty ? (compact ? 4 : 8) : (compact ? 12 : 28);
    if (token.end - start >= minLength &&
        text.length - token.end >= (compact ? 4 : 8) &&
        _punctuation.hasMatch(word) &&
        !_abbreviation.hasMatch(word)) {
      chunks.add(text.substring(start, token.end));
      start = null;
    }
  }
  if (start != null) chunks.add(text.substring(start, previousEnd));
  return chunks;
}
