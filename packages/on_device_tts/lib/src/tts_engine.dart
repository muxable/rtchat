import 'tts_voice.dart';

/// Turns text into speech on the device.
///
/// Callers queue utterances themselves: they await [speak] before speaking
/// the next one, and call [stop] to cut the current one off. Engines don't
/// need to handle overlapping [speak] calls.
///
/// `SystemTtsEngine` uses the platform's voices. Other engines, such as a
/// neural engine with downloadable voice packs, implement this same
/// interface and list only the voices that are ready to speak from [voices].
abstract class TtsEngine {
  /// The normal speaking rate.
  static const normalRate = 0.5;

  /// The voice's own pitch.
  static const normalPitch = 1.0;

  /// Speaks [text] and completes when playback has finished, or once [stop]
  /// cuts it off.
  ///
  /// [voice] is one of this engine's [voices]; when null the engine uses its
  /// default voice. [rate] goes from 0.0 (slowest) to 1.0 (fastest), with
  /// [normalRate] as the normal speed. [pitch] goes from 0.5 to 2.0, with
  /// [normalPitch] as the voice's own pitch; engines that can't change the
  /// pitch ignore it. [language] is the BCP-47 tag of the text's language,
  /// if known: engines whose voices speak several languages read the text
  /// as that language, the platform's voices switch to a voice for it when
  /// no [voice] is given, and engines whose voice decides the language
  /// ignore it.
  ///
  /// Throws if the engine fails to speak.
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = normalRate,
    double pitch = normalPitch,
    String? language,
  });

  /// Stops the current utterance, if any.
  Future<void> stop();

  /// Frees what the engine keeps in memory between utterances, such as a
  /// neural model, e.g. under memory pressure or once speech is turned off.
  /// Unlike [dispose] the engine stays usable: the next [speak] loads what
  /// it needs again. Engines that keep nothing do nothing.
  Future<void> release();

  /// The voices that can speak right now. With [language], a BCP-47 tag such
  /// as `en` or `pt-BR`, only the voices that speak it (see
  /// [TtsVoice.speaks]).
  Future<List<TtsVoice>> voices({String? language});

  /// Stops speaking and releases the engine's resources. The engine can't be
  /// used afterwards.
  Future<void> dispose();
}
