import 'onnx_tts_platform.dart';

/// A neural TTS model running natively on ONNX Runtime.
///
/// ```dart
/// final tts = await OnnxTts.load(modelDir: '/path/to/supertonic-3');
/// final voices = await tts.voices();
/// await tts.speak(['Hello there,', 'how are you?'],
///     language: 'en', voiceId: voices.first.id);
/// await tts.unload();
/// ```
///
/// Only one utterance plays at a time across all models: [speak] throws a
/// `PlatformException` with code `busy` while another one is playing.
class OnnxTts {
  /// The native model's handle.
  final String handle;
  final OnnxTtsPlatform _platform;
  var _nextUtterance = 0;

  OnnxTts._(this.handle, this._platform);

  /// Loads the model in [modelDir], a directory laid out like the
  /// `Supertone/supertonic-3` repository (`onnx/` and `voice_styles/`).
  static Future<OnnxTts> load({
    required String modelDir,
    String modelType = 'supertonic',
    int numThreads = 2,
    OnnxProvider provider = OnnxProvider.cpu,
    OnnxTtsPlatform? platform,
  }) async {
    final p = platform ?? OnnxTtsPlatform.instance;
    final handle = await p.load(
      modelType: modelType,
      modelDir: modelDir,
      numThreads: numThreads,
      provider: provider,
    );
    return OnnxTts._(handle, p);
  }

  Future<List<OnnxVoice>> voices() => _platform.voices(handle);

  /// Speaks [segments] (e.g. the clauses of a message) back to back, and
  /// completes when the last one has finished playing or [stop] cut it off.
  ///
  /// [language] is a BCP-47 tag such as `en` or `pt-BR`. [speed] scales the
  /// speaking rate (1.0 is normal). [steps] trades quality for speed.
  /// [utteranceId] identifies the utterance in [events]; one is made up when
  /// omitted.
  Future<void> speak(
    List<String> segments, {
    required String language,
    required String voiceId,
    double speed = 1.0,
    int steps = 5,
    String? utteranceId,
  }) =>
      _platform.speak(
        handle: handle,
        utteranceId: utteranceId ?? '$handle-${_nextUtterance++}',
        segments: segments,
        language: language,
        voiceId: voiceId,
        speed: speed,
        steps: steps,
      );

  /// Synthesizes [text] without playing it; deterministic with [noiseSeed].
  Future<OnnxSynthesis> synthesize(
    String text, {
    required String language,
    required String voiceId,
    double speed = 1.0,
    int steps = 5,
    int? noiseSeed,
  }) =>
      _platform.synthesize(
        handle: handle,
        text: text,
        language: language,
        voiceId: voiceId,
        speed: speed,
        steps: steps,
        noiseSeed: noiseSeed,
      );

  /// Stops the utterance being spoken, if any.
  Future<void> stop() => _platform.stop();

  /// Progress events of every utterance.
  Stream<OnnxTtsEvent> get events => _platform.events;

  /// Releases the model. It can't be used afterwards.
  Future<void> unload() => _platform.unload(handle);
}
