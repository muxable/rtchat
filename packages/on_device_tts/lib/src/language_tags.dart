import 'package:flutter/foundation.dart';

/// The parts of a BCP-47 language tag that matter for picking a voice: the
/// language, script and region subtags, lowercased. Other subtags (variants,
/// extensions) are dropped.
@immutable
class LanguageTag {
  /// The primary language subtag, e.g. `pt` for `pt-BR`, with legacy codes
  /// replaced by their current ones (`iw` → `he`, `in` → `id`, `ji` → `yi`)
  /// and Norwegian (`no`) read as Bokmål (`nb`).
  final String language;

  /// The script subtag, e.g. `hant` for `zh-Hant`; for Chinese, implied by
  /// the region when the tag has none (`zh-TW` is `hant`, `zh-CN` `hans`).
  final String? script;

  /// The region subtag, e.g. `br` for `pt-BR` or `419` for `es-419`.
  final String? region;

  const LanguageTag(this.language, {this.script, this.region});

  /// Parses [tag], e.g. `pt-BR`, `zh_Hant_TW` or `EN`. Case and `_` vs `-`
  /// don't matter.
  factory LanguageTag.parse(String tag) {
    final parts = tag.trim().replaceAll('_', '-').toLowerCase().split('-');
    var language = parts.first;
    language = _aliases[language] ?? language;
    String? script;
    String? region;
    for (final part in parts.skip(1)) {
      if (script == null && region == null && _isScript(part)) {
        script = part;
      } else if (region == null && _isRegion(part)) {
        region = part;
      } else {
        break; // A variant or extension: not used for matching.
      }
    }
    if (language == 'zh' && script == null && region != null) {
      script = _chineseScripts[region];
    }
    return LanguageTag(language, script: script, region: region);
  }

  static bool _isScript(String part) =>
      part.length == 4 && RegExp(r'^[a-z]{4}$').hasMatch(part);

  static bool _isRegion(String part) =>
      RegExp(r'^([a-z]{2}|[0-9]{3})$').hasMatch(part);

  static const _aliases = {'iw': 'he', 'in': 'id', 'ji': 'yi', 'no': 'nb'};

  static const _chineseScripts = {
    'tw': 'hant',
    'hk': 'hant',
    'mo': 'hant',
    'cn': 'hans',
    'sg': 'hans',
    'my': 'hans',
  };

  /// How well a voice for [have] suits text in [wanted]; 0 if it doesn't.
  ///
  /// * 4: the same language, script and region.
  /// * 3: [have] is the bare language (or language and script) of [wanted],
  ///   e.g. a `pt` voice for `pt-BR` text.
  /// * 2: [wanted] is the bare language and [have] adds a region, e.g. an
  ///   `en-US` voice for `en` text.
  /// * 1: the same language in another region, e.g. a `pt-PT` voice for
  ///   `pt-BR` text.
  ///
  /// Scripts must agree when both are known: a `zh-Hans` voice doesn't read
  /// `zh-Hant` (or `zh-TW`) text.
  static int matchScore(String wanted, String have) {
    final want = LanguageTag.parse(wanted);
    final got = LanguageTag.parse(have);
    if (want.language.isEmpty || want.language != got.language) return 0;
    if (want.script != null &&
        got.script != null &&
        want.script != got.script) {
      return 0;
    }
    if (want.region == got.region) {
      if (want.script == got.script) return 4;
      return got.script == null ? 3 : 2;
    }
    if (got.region == null) return 3;
    if (want.region == null) return 2;
    return 1;
  }

  /// The tag in [available] whose voices best suit text in [wanted] (see
  /// [matchScore]), the first of equally good ones, or null if none speaks
  /// its language.
  static String? bestMatch(String wanted, Iterable<String> available) {
    String? best;
    var bestScore = 0;
    for (final have in available) {
      final score = matchScore(wanted, have);
      if (score > bestScore) {
        best = have;
        bestScore = score;
      }
    }
    return best;
  }

  @override
  bool operator ==(Object other) =>
      other is LanguageTag &&
      other.language == language &&
      other.script == script &&
      other.region == region;

  @override
  int get hashCode => Object.hash(language, script, region);

  @override
  String toString() => [
        language,
        if (script != null) script,
        if (region != null) region
      ].join('-');
}
