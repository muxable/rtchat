import 'dart:async';

import 'package:path/path.dart' as p;

import 'onnx/onnx_tts.dart';
import 'onnx/onnx_tts_platform.dart';
import 'tts_engine.dart';
import 'tts_voice.dart';
import 'voice_packs/installed_voice_pack.dart';
import 'voice_packs/voice_pack.dart';

/// Thrown when a [NeuralTtsEngine] can't speak with its voice pack.
class NeuralTtsException implements Exception {
  final String message;

  const NeuralTtsException(this.message);

  @override
  String toString() => 'NeuralTtsException: $message';
}

/// Speaks with an installed neural voice pack, synthesized on the device by
/// the native ONNX Runtime engine ([OnnxTts]).
///
/// The model loads on the first [speak] (or [load]) and stays loaded, so
/// later utterances start quickly. [release] unloads it to free memory, and
/// the next [speak] loads it again; [dispose] unloads it for good.
///
/// [speak] hands the whole text to the native engine as one segment. The
/// native side synthesizes it, splitting text longer than 300 UTF-16 code
/// units (120 for Japanese and Korean) itself, and streams the audio out as
/// it is made.
///
/// The native side plays one utterance at a time for every engine, so don't
/// [speak] on two engines at once.
class NeuralTtsEngine implements TtsEngine {
  /// The pack the engine speaks with. Its directory is laid out like the
  /// `Supertone/supertonic-3` repository (`onnx/` and `voice_styles/`).
  final InstalledVoicePack pack;

  /// ONNX Runtime's thread count.
  final int numThreads;

  /// The execution provider; unavailable ones fall back to the CPU.
  final OnnxProvider provider;

  /// Flow-matching steps per synthesis: fewer is faster, more sounds better.
  final int steps;

  final OnnxTtsPlatform _platform;
  final String _utterancePrefix;
  var _nextUtterance = 0;
  static var _engines = 0;

  Future<OnnxTts>? _model;
  String? _activeUtterance;
  // Bumped by [stop], so an utterance waiting for the model knows it was cut
  // off.
  var _stops = 0;
  var _isDisposed = false;

  /// The speeds the native engine accepts; others are clamped.
  static const minSpeed = 0.7;
  static const maxSpeed = 2.0;

  /// Throws a [NeuralTtsException] if the engine can't speak with [pack]
  /// (see [canSpeak]). The model itself loads later, on first use.
  NeuralTtsEngine(
    this.pack, {
    this.numThreads = 2,
    this.provider = OnnxProvider.cpu,
    this.steps = 5,
    OnnxTtsPlatform? platform,
  })  : _platform = platform ?? OnnxTtsPlatform.instance,
        _utterancePrefix = 'neural-${_engines++}-' {
    if (!canSpeak(pack.pack)) {
      throw NeuralTtsException(
          'Unsupported model type ${pack.pack.modelType.name} in ${pack.id}');
    }
  }

  /// Whether a [NeuralTtsEngine] can speak with [pack].
  static bool canSpeak(VoicePack pack) =>
      pack.modelType == VoicePackModelType.supertonic;

  /// Maps a [TtsEngine] rate (0..1, 0.5 normal) to the native speed (1.0
  /// normal) as `2 × rate`, clamped to [minSpeed]..[maxSpeed]. That is how
  /// `flutter_tts` sets Android's speech rate, so a rate sounds about as fast
  /// as with the system voices there: 0.8 (the app's Android default) is
  /// 1.6×.
  static double speedForRate(double rate) =>
      (rate * 2).clamp(minSpeed, maxSpeed).toDouble();

  /// The native events of this engine's utterances: when each first played
  /// audio, and how it ended. Broadcast.
  Stream<OnnxTtsEvent> get events => _platform.events
      .where((event) => event.utteranceId.startsWith(_utterancePrefix));

  /// Whether the model is loaded or loading.
  bool get isLoaded => _model != null;

  /// Loads the model, if it isn't already. [speak] calls this itself; call it
  /// earlier to make the first utterance start sooner.
  Future<void> load() => _load();

  Future<OnnxTts> _load() {
    if (_isDisposed) throw StateError('NeuralTtsEngine was disposed');
    final model = _model ??= OnnxTts.load(
      modelDir: pack.directory,
      modelType: pack.pack.modelType.name,
      numThreads: numThreads,
      provider: provider,
      platform: _platform,
    );
    // Try again next time rather than keep a failure.
    model.then((_) {}, onError: (Object error) {
      if (identical(_model, model)) _model = null;
    });
    return model;
  }

  /// Speaks [text], completing once it has played or [stop] cut it off.
  ///
  /// [language] (a BCP-47 tag) is the text's language; without it, the
  /// [voice]'s locale, else English. [voice] is one of [voices]; without it
  /// the pack's first speaker speaks. [rate] maps to the native speed with
  /// [speedForRate]. [pitch] is ignored: the model has no pitch control.
  ///
  /// Throws if the model can't load (a `PlatformException` with code
  /// `load_failed`) or speaking fails (`speak_failed`, `busy`, `bad_args`).
  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    final lang = language ?? voice?.locale ?? 'en';
    final message = text.trim();
    if (message.isEmpty) return;
    final voiceId = voice?.id ?? _speakerIds().firstOrNull;
    if (voiceId == null) throw NeuralTtsException('${pack.id} has no voices');
    final stops = _stops;
    final model = await _load();
    if (stops != _stops || _isDisposed) return;
    final id = '$_utterancePrefix${_nextUtterance++}';
    _activeUtterance = id;
    try {
      await model.speak([message],
          language: lang,
          voiceId: voiceId,
          speed: speedForRate(rate),
          steps: steps,
          utteranceId: id);
    } finally {
      if (_activeUtterance == id) _activeUtterance = null;
    }
  }

  /// The native voice id of each of the pack's speakers: the name of its
  /// voice style file (`F1` for `voice_styles/F1.json`), else its name.
  List<String> _speakerIds() {
    final styles = pack.pack.config['voice_styles'];
    return [
      for (final speaker in pack.pack.speakers)
        if (styles is List && styles.elementAtOrNull(speaker.index) is String)
          p.posix.basenameWithoutExtension(styles[speaker.index] as String)
        else
          speaker.name,
    ];
  }

  /// Stops this engine's utterance, if it is speaking or about to. Whatever
  /// another engine is saying is left alone.
  @override
  Future<void> stop() async {
    _stops++;
    if (_activeUtterance == null) return;
    await _platform.stop();
  }

  /// One voice per speaker and language of the pack, with the language as
  /// its locale, so a 10-speaker, 31-language pack lists 310. Doesn't load
  /// the model.
  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    final ids = _speakerIds();
    final voices = [
      for (final (i, speaker) in pack.pack.speakers.indexed)
        for (final locale in speaker.language == null
            ? pack.pack.languages
            : [speaker.language!])
          TtsVoice(id: ids[i], name: speaker.name, locale: locale),
    ];
    if (language == null) return voices;
    return voices.where((voice) => voice.speaks(language)).toList();
  }

  /// Stops speaking and unloads the model to free its memory. The next
  /// [speak] loads it again.
  ///
  /// Unloading natively cuts off whatever utterance is playing, even another
  /// engine's, so don't release while another engine speaks.
  Future<void> release() async {
    final model = _model;
    _model = null;
    if (model == null) return;
    await stop();
    final OnnxTts loaded;
    try {
      loaded = await model;
    } catch (_) {
      return; // Nothing loaded, nothing to release.
    }
    await loaded.unload();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await release();
  }
}
