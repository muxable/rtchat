import 'dart:async';
import 'dart:math';

import 'package:on_device_tts/on_device_tts.dart';

/// One [FakeTtsEngine.speak] call.
class FakeUtterance {
  final String text;
  final TtsVoice? voice;
  final double rate;
  final double pitch;
  final String? language;

  FakeUtterance(this.text,
      {this.voice, required this.rate, required this.pitch, this.language});

  @override
  String toString() => 'FakeUtterance($text, rate: $rate, pitch: $pitch)';
}

/// A [TtsEngine] that records what it's asked to say.
///
/// Speech finishes at once, unless [holdSpeech] is set: then each utterance
/// lasts until [finishSpeaking] or [stop] is called, like speech that can't
/// keep up with chat.
class FakeTtsEngine implements TtsEngine {
  final List<FakeUtterance> utterances = [];
  var stopCount = 0;
  var releaseCount = 0;
  var isDisposed = false;
  var holdSpeech = false;
  List<TtsVoice> availableVoices;

  /// Called with the text of each utterance; speech lasts until the future
  /// it returns completes.
  Future<void> Function(String text)? onSpeak;

  /// The error the next [speak] throws, if any.
  Object? failNext;

  /// Where engines sharing it log `<name>: <text>` and `<name> dispose`,
  /// and how many speak at once.
  final SpeechLog? log;
  final String name;

  final List<Completer<void>> _speaking = [];

  FakeTtsEngine(
      {this.availableVoices = const [], this.log, this.name = 'engine'});

  /// The text of every utterance, in order.
  List<String> get spoken => utterances.map((u) => u.text).toList();

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw error;
    }
    utterances.add(FakeUtterance(text,
        voice: voice, rate: rate, pitch: pitch, language: language));
    log?.events.add('$name: $text');
    if (log case final log?) {
      log.maxSpeaking = max(log.maxSpeaking, ++log.speaking);
    }
    try {
      await onSpeak?.call(text);
      if (holdSpeech) {
        final done = Completer<void>();
        _speaking.add(done);
        await done.future;
      }
    } finally {
      log?.speaking--;
    }
  }

  /// Finishes every utterance that's still being spoken.
  void finishSpeaking() {
    for (final done in _speaking) {
      if (!done.isCompleted) done.complete();
    }
    _speaking.clear();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    finishSpeaking();
  }

  @override
  Future<void> release() async => releaseCount++;

  @override
  Future<List<TtsVoice>> voices({String? language}) async => language == null
      ? availableVoices
      : availableVoices.where((voice) => voice.speaks(language)).toList();

  @override
  Future<void> dispose() async {
    log?.events.add('$name dispose');
    isDisposed = true;
    finishSpeaking();
  }
}

/// What engines sharing it did, in order, and the most that spoke at once.
class SpeechLog {
  final events = <String>[];
  var speaking = 0;
  var maxSpeaking = 0;
}

/// The speakers of Supertonic 3.
const supertonicSpeakers = [
  'F1', 'F2', 'F3', 'F4', 'F5', 'M1', 'M2', 'M3', 'M4', 'M5', //
];

/// Each of [speakers] in each of [languages], as a multilingual pack lists
/// its voices.
List<TtsVoice> packVoices(List<String> languages,
        {List<String> speakers = supertonicSpeakers}) =>
    [
      for (final speaker in speakers)
        for (final language in languages)
          TtsVoice(id: speaker, name: speaker, locale: language),
    ];
