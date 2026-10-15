import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'clause_splitter.dart';
import 'onnx/onnx_tts.dart';
import 'onnx/onnx_tts_platform.dart';
import 'tts_engine.dart';
import 'tts_voice.dart';
import 'voice_packs/installed_voice_pack.dart';
import 'voice_packs/voice_pack.dart';

/// Thrown when an installed voice pack can't be spoken with by a
/// [NeuralTtsEngine], e.g. its model type isn't supported.
class NeuralTtsException implements Exception {
  final String message;

  const NeuralTtsException(this.message);

  @override
  String toString() => 'NeuralTtsException: $message';
}

/// Thrown when a [NeuralTtsEngine]'s model fails to load: the native
/// engine's `load_failed`, which includes running out of memory, or a
/// missing or broken model. [cause] is the original error.
class NeuralTtsLoadException extends NeuralTtsException {
  final Object cause;

  const NeuralTtsLoadException(super.message, this.cause);

  @override
  String toString() => 'NeuralTtsLoadException: $message ($cause)';
}

/// Speaks with a neural voice pack, synthesized on the device by the native
/// ONNX Runtime engine ([OnnxTts]).
///
/// The model loads on the first [speak] (or an explicit [load]) and stays
/// loaded, so later utterances start quickly. [release] unloads it to free
/// memory, and the next [speak] loads it again; [dispose] unloads it for
/// good.
///
/// [speak] splits the text into clauses with a [ClauseSplitter] and hands
/// them to the native engine, which plays each clause while it synthesizes
/// the next one, so the first audio comes after the first clause rather than
/// the whole message. Audio streams to the audio output; nothing is written
/// to a file.
///
/// Only one utterance plays at a time across every engine on the native
/// side, so don't [speak] on two engines at once.
class NeuralTtsEngine implements TtsEngine {
  /// The pack the engine speaks with.
  final InstalledVoicePack pack;

  /// The language spoken when [speak] isn't told one, a BCP-47 tag.
  final String defaultLanguage;

  /// ONNX Runtime's thread count.
  final int numThreads;

  /// The execution provider; unavailable ones fall back to the CPU.
  final OnnxProvider provider;

  /// Flow-matching steps per clause: fewer is faster, more sounds better.
  final int steps;

  /// Whether [speak] splits text into clauses. Without, the first audio
  /// waits for the whole text (up to the native chunk limit) to be
  /// synthesized; this is for comparing the two.
  final bool splitClauses;

  final OnnxTtsPlatform _platform;
  final String _utterancePrefix;
  var _nextUtterance = 0;

  Future<OnnxTts>? _model;
  String? _activeUtterance;
  // Bumped by [stop], so an utterance waiting for the model to load knows
  // it was cut off.
  var _stops = 0;
  var _isDisposed = false;

  static var _engines = 0;

  /// The slowest speed the native engine accepts; slower is clamped.
  static const minSpeed = 0.7;

  /// The highest speed the native engine accepts; faster is clamped.
  static const maxSpeed = 2.0;

  /// Clause length limits of the native engine, in UTF-16 code units: it
  /// splits longer text itself, without regard for clauses.
  static const maxSegmentLength = 300;
  static const maxSegmentLengthCjk = 120;

  /// Throws a [NeuralTtsException] if [pack] isn't a model type the engine
  /// can load. The model itself loads later, on first use.
  NeuralTtsEngine(
    this.pack, {
    this.defaultLanguage = 'en',
    this.numThreads = 2,
    this.provider = OnnxProvider.cpu,
    this.steps = 5,
    this.splitClauses = true,
    OnnxTtsPlatform? platform,
  })  : _platform = platform ?? OnnxTtsPlatform.instance,
        _utterancePrefix = 'neural-${_engines++}-' {
    if (!canSpeak(pack.pack)) {
      throw NeuralTtsException(
          'Unsupported model type ${pack.pack.modelType.name} in ${pack.id}');
    }
    modelDirectory; // Throws if the layout doesn't fit the native engine.
  }

  /// Whether a [NeuralTtsEngine] can speak with [pack].
  static bool canSpeak(VoicePack pack) =>
      pack.modelType == VoicePackModelType.supertonic;

  /// Maps a [TtsEngine] rate (0..1, [TtsEngine.normalRate] = 0.5 is normal)
  /// to the native speed (1.0 is normal): `speed = 2 × rate`, clamped to
  /// [minSpeed]..[maxSpeed]. That is how `flutter_tts` sets Android's speech
  /// rate, so a rate sounds about as fast as it does with the system voices
  /// there: 0.5 is 1×, 0.8 (the app's Android default) 1.6×, 1.0 2×, and
  /// anything at or below 0.35 0.7×.
  static double speedForRate(double rate) =>
      (rate * 2).clamp(minSpeed, maxSpeed).toDouble();

  /// The longest clause the engine passes for [language].
  static int maxSegmentLengthFor(String language) {
    final primary = language.toLowerCase().split(RegExp('[-_]')).first;
    return primary == 'ko' || primary == 'ja'
        ? maxSegmentLengthCjk
        : maxSegmentLength;
  }

  /// The directory the native engine loads the model from, worked out from
  /// the paths in the pack's `config`: `voice_styles/*.json` and the model
  /// files either next to it in `onnx/` or beside it.
  String get modelDirectory {
    final config = pack.pack.config;
    final styles = config['voice_styles'];
    final firstStyle =
        styles is List && styles.isNotEmpty ? styles.first : null;
    var root = '.';
    if (firstStyle is String) {
      final stylesDir = p.posix.dirname(firstStyle);
      if (p.posix.basename(stylesDir) != 'voice_styles') {
        throw NeuralTtsException(
            '${pack.id}: voice styles must be in voice_styles/');
      }
      root = p.posix.dirname(stylesDir);
    }
    for (final key in const [
      'duration_predictor',
      'text_encoder',
      'vector_estimator',
      'vocoder',
      'tts_json',
      'unicode_indexer',
    ]) {
      final path = config[key];
      if (path is! String) continue;
      final dir = p.posix.dirname(path);
      final onnx = p.posix.normalize(p.posix.join(root, 'onnx'));
      if (dir != root && dir != onnx) {
        throw NeuralTtsException('${pack.id}: $key must be in $onnx');
      }
    }
    return p.normalize(p.join(pack.directory, root));
  }

  /// Events of this engine's utterances: when each first played audio
  /// ([OnnxTtsEventType.firstAudio], for time to first audio), and how it
  /// ended. Broadcast.
  Stream<OnnxTtsEvent> get events => _platform.events
      .where((event) => event.utteranceId.startsWith(_utterancePrefix));

  /// Whether the model is loaded or loading.
  bool get isLoaded => _model != null;

  /// Loads the model, if it isn't already. [speak] calls this itself; call it
  /// earlier to make the first utterance start sooner.
  Future<void> load() => _load();

  Future<OnnxTts> _load() {
    _checkNotDisposed();
    final model = _model ??= OnnxTts.load(
      modelDir: modelDirectory,
      modelType: pack.pack.modelType.name,
      numThreads: numThreads,
      provider: provider,
      platform: _platform,
    ).catchError(
      (Object error) => throw NeuralTtsLoadException(
          "Couldn't load ${pack.id}: ${error is PlatformException ? error.message : error}",
          error),
      test: (error) =>
          error is PlatformException && error.code == 'load_failed',
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
  /// [voice]'s locale, else [defaultLanguage]. [voice] is one of [voices];
  /// without it the pack's first speaker speaks. [rate] maps to the native
  /// speed with [speedForRate]. [pitch] is ignored: the model has no pitch
  /// control.
  ///
  /// Throws a [NeuralTtsLoadException] if the model can't load, and a
  /// `PlatformException` if speaking fails (`speak_failed`, `busy`,
  /// `bad_args`).
  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    _checkNotDisposed();
    final lang = language ?? voice?.locale ?? defaultLanguage;
    final segments = splitClauses
        ? ClauseSplitter(maxLength: maxSegmentLengthFor(lang)).split(text)
        : [if (text.trim().isNotEmpty) text.trim()];
    if (segments.isEmpty) return;
    final stops = _stops;
    final model = await _load();
    if (stops != _stops || _isDisposed) return;
    final voiceId = voice?.id ?? await _defaultVoiceId(model);
    if (stops != _stops || _isDisposed) return;
    final id = '$_utterancePrefix${_nextUtterance++}';
    _activeUtterance = id;
    try {
      await model.speak(
        segments,
        language: lang,
        voiceId: voiceId,
        speed: speedForRate(rate),
        steps: steps,
        utteranceId: id,
      );
    } finally {
      if (_activeUtterance == id) _activeUtterance = null;
    }
  }

  Future<String> _defaultVoiceId(OnnxTts model) async {
    final speakers = _speakerVoiceIds();
    if (speakers.isNotEmpty) return speakers.first;
    final voices = await model.voices();
    if (voices.isEmpty) {
      throw NeuralTtsException('${pack.id} has no voices');
    }
    return voices.first.id;
  }

  /// The native voice id of each of the pack's speakers, in order: the name
  /// of its voice style file (`F1` for `voice_styles/F1.json`), else its
  /// name.
  List<String> _speakerVoiceIds() {
    final styles = pack.pack.config['voice_styles'];
    return [
      for (final speaker in pack.pack.speakers)
        if (styles is List &&
            speaker.index >= 0 &&
            speaker.index < styles.length &&
            styles[speaker.index] is String)
          p.posix.basenameWithoutExtension(styles[speaker.index] as String)
        else
          speaker.name,
    ];
  }

  /// Stops this engine's utterance, if it is speaking or about to.
  ///
  /// The native engine plays one utterance at a time for every engine, so
  /// this leaves alone whatever another engine is saying.
  @override
  Future<void> stop() async {
    _stops++;
    if (_activeUtterance == null) return;
    await _platform.stop();
  }

  /// One voice per speaker and language of the pack, with the language as
  /// its locale (so a 10-speaker, 31-language pack lists 310). Doesn't load
  /// the model unless the pack lists no speakers.
  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    final languages = pack.pack.languages;
    final ids = _speakerVoiceIds();
    final List<(String, String, String?)> speakers;
    if (ids.isNotEmpty) {
      speakers = [
        for (var i = 0; i < ids.length; i++)
          (ids[i], pack.pack.speakers[i].name, pack.pack.speakers[i].language),
      ];
    } else {
      final model = await _load();
      speakers = [
        for (final voice in await model.voices())
          (voice.id, voice.name, voice.language),
      ];
    }
    final voices = [
      for (final (id, name, speakerLanguage) in speakers)
        for (final locale
            in speakerLanguage == null ? languages : [speakerLanguage])
          TtsVoice(id: id, name: name, locale: locale),
    ];
    if (language == null) return voices;
    return voices.where((voice) => voice.speaks(language)).toList();
  }

  /// Stops speaking and unloads the model to free its memory, e.g. under
  /// memory pressure. The next [speak] loads it again, which delays its
  /// first audio by the load time (Supertonic 3: about 0.7 to 1.2 s on the
  /// x86_64 emulator; see `doc/native_contract.md`).
  ///
  /// Unloading natively also cuts off whatever utterance is playing, even
  /// another engine's, so don't release while another engine speaks.
  @override
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

  void _checkNotDisposed() {
    if (_isDisposed) throw StateError('NeuralTtsEngine was disposed');
  }
}
