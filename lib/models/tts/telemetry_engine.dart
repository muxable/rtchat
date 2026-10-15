import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts/telemetry.dart';

/// A neural engine that tells [telemetry] how long its model takes to load,
/// how often it reloads, and how long each utterance takes to start playing.
///
/// It loads the model itself before speaking, to time the load apart from
/// the first audio, and otherwise does what [engine] does.
class TelemetryTtsEngine implements TtsEngine {
  final TtsEngine engine;
  final TtsTelemetry telemetry;
  final NeuralEngineInfo info;
  final Stream<OnnxTtsEvent> _events;
  final bool Function() _isLoaded;
  final Future<void> Function() _load;

  StreamSubscription<OnnxTtsEvent>? _subscription;
  var _loads = 0;
  // bumped by [stop], so a speak waiting for the model knows it was cut off.
  var _stops = 0;

  /// [events] are [engine]'s utterance events; [isLoaded] and [load] tell
  /// whether its model is loaded (or loading) and load it.
  TelemetryTtsEngine({
    required this.engine,
    required this.telemetry,
    required this.info,
    required Stream<OnnxTtsEvent> events,
    required bool Function() isLoaded,
    required Future<void> Function() load,
  })  : _events = events,
        _isLoaded = isLoaded,
        _load = load;

  factory TelemetryTtsEngine.neural(
          NeuralTtsEngine engine, TtsTelemetry telemetry) =>
      TelemetryTtsEngine(
        engine: engine,
        telemetry: telemetry,
        info: NeuralEngineInfo.of(engine),
        events: engine.events,
        isLoaded: () => engine.isLoaded,
        load: engine.load,
      );

  void _onEvent(OnnxTtsEvent event) {
    if (event.type == OnnxTtsEventType.firstAudio) {
      telemetry.firstAudio(event.elapsed);
    }
  }

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    _subscription ??= _events.listen(_onEvent, onError: (Object _) {});
    telemetry.neuralEngineInUse(info);
    if (!_isLoaded()) {
      final stops = _stops;
      final isReload = _loads > 0;
      final stopwatch = Stopwatch()..start();
      try {
        await _load();
      } catch (_) {
        telemetry.modelLoaded(stopwatch.elapsed,
            isReload: isReload, succeeded: false);
        rethrow;
      }
      _loads++;
      telemetry.modelLoaded(stopwatch.elapsed,
          isReload: isReload, succeeded: true);
      if (stops != _stops) return;
    }
    await engine.speak(text,
        voice: voice, rate: rate, pitch: pitch, language: language);
  }

  @override
  Future<void> stop() {
    _stops++;
    return engine.stop();
  }

  @override
  Future<void> release() => engine.release();

  @override
  Future<List<TtsVoice>> voices({String? language}) =>
      engine.voices(language: language);

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await engine.dispose();
  }
}
