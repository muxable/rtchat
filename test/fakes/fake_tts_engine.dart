import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';

/// One [FakeTtsEngine.speak] call.
class FakeUtterance {
  final String text;
  final TtsVoice? voice;
  final double rate;
  final double pitch;

  FakeUtterance(this.text,
      {this.voice, required this.rate, required this.pitch});

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
  var isDisposed = false;
  var holdSpeech = false;
  List<TtsVoice> availableVoices;

  /// Called with the text of each utterance; speech lasts until the future
  /// it returns completes.
  Future<void> Function(String text)? onSpeak;

  /// The error the next [speak] throws, if any.
  Object? failNext;

  final List<Completer<void>> _speaking = [];

  FakeTtsEngine({this.availableVoices = const []});

  /// The text of every utterance, in order.
  List<String> get spoken => utterances.map((u) => u.text).toList();

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
  }) async {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw error;
    }
    utterances.add(FakeUtterance(text, voice: voice, rate: rate, pitch: pitch));
    await onSpeak?.call(text);
    if (holdSpeech) {
      final done = Completer<void>();
      _speaking.add(done);
      await done.future;
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
  Future<List<TtsVoice>> voices({String? language}) async => language == null
      ? availableVoices
      : availableVoices.where((voice) => voice.speaks(language)).toList();

  @override
  Future<void> dispose() async {
    isDisposed = true;
    finishSpeaking();
  }
}
