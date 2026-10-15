import 'package:flutter/foundation.dart';

/// A voice that a `TtsEngine` can speak with.
@immutable
class TtsVoice {
  /// Identifies the voice within its engine; pass the voice back to the
  /// engine that listed it.
  final String id;

  /// A name to show to people, e.g. `Samantha` or `en-us-x-sfg-local`.
  final String name;

  /// The BCP-47 tag of the language the voice speaks, e.g. `en-US`.
  final String locale;

  const TtsVoice({required this.id, required this.name, required this.locale});

  /// The language subtag of [locale], lowercased, e.g. `en` for `en-US`.
  String get languageCode => _normalize(locale).split('-').first;

  /// Whether this voice speaks [language], a BCP-47 tag such as `en` or
  /// `pt-BR`. A bare language matches every region; a tag with a region only
  /// matches that region. Case and `_` vs `-` don't matter.
  bool speaks(String language) {
    final wanted = _normalize(language);
    final have = _normalize(locale);
    return have == wanted || have.startsWith('$wanted-');
  }

  static String _normalize(String tag) =>
      tag.replaceAll('_', '-').toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is TtsVoice &&
      other.id == id &&
      other.name == name &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(id, name, locale);

  @override
  String toString() => 'TtsVoice($id, $name, $locale)';
}
