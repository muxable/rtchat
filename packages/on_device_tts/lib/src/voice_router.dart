import 'language_tags.dart';
import 'stable_hash.dart';
import 'tts_engine.dart';
import 'tts_voice.dart';

/// Where [VoiceRouter.route] sends text in one language: an [engine], the
/// [language] tag to pass it, and the [voices] it has for that language.
class VoiceRoute {
  final TtsEngine engine;

  /// The engine's own tag for the language, e.g. `pt` for `pt-BR` text when
  /// the engine lists `pt`. Pass this to [TtsEngine.speak].
  final String language;

  /// The engine's voices for [language], in the engine's order; never empty.
  final List<TtsVoice> voices;

  const VoiceRoute(this.engine, this.language, this.voices);

  /// The voice with [id], or the first voice if there is none.
  TtsVoice voiceWithId(String? id) =>
      voices.where((voice) => voice.id == id).firstOrNull ?? voices.first;

  /// A voice picked by [key], e.g. a chatter's identity: the same key gets
  /// the same voice on every run and platform (it's hashed with [fnv1a32]),
  /// as long as [voices] stays the same.
  TtsVoice voiceForKey(String key) => voices[fnv1a32(key) % voices.length];
}

/// Picks which of several engines reads text in a given language, e.g. one
/// engine per installed voice pack.
///
/// [engines] are in order of preference: text goes to the first engine with
/// a voice for its language, matched with [LanguageTag.matchScore] (a `pt`
/// voice reads `pt-BR` and an `en-US` voice reads `en`, but a `zh-Hans`
/// voice doesn't read `zh-Hant`), and to its best-matching tag. When no
/// engine speaks the language, [route] returns null and the caller uses its
/// fallback, such as the platform's voices.
///
/// The languages an engine speaks are the locales of its
/// [TtsEngine.voices], listed once per engine.
class VoiceRouter {
  /// The engines in order of preference.
  final List<TtsEngine> engines;

  final void Function(Object error, StackTrace stack)? _onError;
  final Map<TtsEngine, Future<List<TtsVoice>>> _voices = {};

  /// [onError] hears about engines whose voices can't be listed; they are
  /// skipped, and listed again next time.
  VoiceRouter(Iterable<TtsEngine> engines,
      {void Function(Object error, StackTrace stack)? onError})
      : engines = List.unmodifiable(engines),
        _onError = onError;

  /// Routes nothing: every language goes to the fallback.
  static final empty = VoiceRouter(const []);

  /// The engine, language and voices for text in [language] (a BCP-47
  /// tag), or null if no engine speaks it.
  Future<VoiceRoute?> route(String language) async {
    for (final engine in engines) {
      final voices = await _voicesOf(engine);
      final match =
          LanguageTag.bestMatch(language, {for (final v in voices) v.locale});
      if (match == null) continue;
      return VoiceRoute(engine, match, [
        for (final voice in voices)
          if (voice.locale == match) voice,
      ]);
    }
    return null;
  }

  /// Every language the engines speak, as their own tags, without repeats.
  Future<List<String>> languages() async => {
        for (final engine in engines)
          for (final voice in await _voicesOf(engine)) voice.locale,
      }.toList();

  Future<List<TtsVoice>> _voicesOf(TtsEngine engine) async {
    try {
      return await (_voices[engine] ??= engine.voices());
    } catch (e, st) {
      _voices.remove(engine);
      _onError?.call(e, st);
      return const [];
    }
  }
}
