import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../device_memory.dart';

/// The ONNX Runtime execution provider a model runs on.
///
/// Providers the platform doesn't have (e.g. [coreml] on Android) fall back
/// to [cpu].
enum OnnxProvider {
  cpu,

  /// XNNPACK's optimized CPU kernels (Android and iOS).
  xnnpack,

  /// Android's Neural Networks API.
  nnapi,

  /// Core ML (iOS).
  coreml,
}

/// A voice of a loaded model.
@immutable
class OnnxVoice {
  final String id;
  final String name;

  /// The BCP-47 tag of the voice's language, or null when the voice speaks
  /// every language of the model.
  final String? language;

  const OnnxVoice({required this.id, required this.name, this.language});

  factory OnnxVoice.fromMap(Map<Object?, Object?> map) => OnnxVoice(
        id: map['id'] as String,
        name: map['name'] as String,
        language: map['language'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is OnnxVoice &&
      other.id == id &&
      other.name == name &&
      other.language == language;

  @override
  int get hashCode => Object.hash(id, name, language);

  @override
  String toString() => 'OnnxVoice($id, $name, $language)';
}

/// Audio made by [OnnxTtsPlatform.synthesize]: mono float PCM in [-1, 1].
class OnnxSynthesis {
  final int sampleRate;
  final Float32List pcm;

  const OnnxSynthesis({required this.sampleRate, required this.pcm});

  /// The audio's length.
  Duration get duration =>
      Duration(microseconds: pcm.length * 1000000 ~/ sampleRate);
}

/// What an [OnnxTtsEvent] reports.
enum OnnxTtsEventType {
  /// The first audio of the utterance went to the audio output.
  firstAudio,

  /// The last segment finished playing.
  done,

  /// `stop` cut the utterance off.
  stopped,

  /// Synthesis or playback failed; see [OnnxTtsEvent.message].
  error,
}

/// Progress of an utterance from [OnnxTtsPlatform.speak].
@immutable
class OnnxTtsEvent {
  final String utteranceId;
  final OnnxTtsEventType type;

  /// Time since the `speak` call.
  final Duration elapsed;
  final String? message;

  const OnnxTtsEvent({
    required this.utteranceId,
    required this.type,
    required this.elapsed,
    this.message,
  });

  /// Parses an event map, or returns null for an unknown event type.
  static OnnxTtsEvent? fromMap(Map<Object?, Object?> map) {
    final type = OnnxTtsEventType.values
        .where((type) => type.name == map['type'])
        .firstOrNull;
    if (type == null) return null;
    return OnnxTtsEvent(
      utteranceId: map['utteranceId'] as String,
      type: type,
      elapsed: Duration(milliseconds: (map['elapsedMs'] as num).toInt()),
      message: map['message'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OnnxTtsEvent &&
      other.utteranceId == utteranceId &&
      other.type == type &&
      other.elapsed == elapsed &&
      other.message == message;

  @override
  int get hashCode => Object.hash(utteranceId, type, elapsed, message);

  @override
  String toString() =>
      'OnnxTtsEvent($utteranceId, ${type.name}, ${elapsed.inMilliseconds} ms'
      '${message == null ? '' : ', $message'})';
}

/// The `on_device_tts/onnx` platform channels, typed. See
/// `doc/native_contract.md` for what each call does.
///
/// Calls throw [PlatformException]s with the codes listed there, e.g.
/// `load_failed` or `busy`, and [MissingPluginException] on platforms
/// without the native engine.
class OnnxTtsPlatform {
  static const methodChannelName = 'on_device_tts/onnx';
  static const eventChannelName = 'on_device_tts/onnx/events';
  static const memoryChannelName = 'on_device_tts/memory';

  /// The instance `OnnxTts` uses by default;
  /// replace it in tests.
  static OnnxTtsPlatform instance = OnnxTtsPlatform();

  final MethodChannel _methods;
  final EventChannel _eventChannel;
  final EventChannel _memoryChannel;
  Stream<OnnxTtsEvent>? _events;
  Stream<int>? _memoryPressure;

  OnnxTtsPlatform(
      {MethodChannel? methods, EventChannel? events, EventChannel? memory})
      : _methods = methods ?? const MethodChannel(methodChannelName),
        _eventChannel = events ?? const EventChannel(eventChannelName),
        _memoryChannel = memory ?? const EventChannel(memoryChannelName);

  /// Loads the model in [modelDir] and returns its handle.
  Future<String> load({
    String modelType = 'supertonic',
    required String modelDir,
    int numThreads = 2,
    OnnxProvider provider = OnnxProvider.cpu,
  }) async {
    final handle = await _methods.invokeMethod<String>('load', {
      'modelType': modelType,
      'modelDir': modelDir,
      'numThreads': numThreads,
      'provider': provider.name,
    });
    if (handle == null) {
      throw PlatformException(code: 'load_failed', message: 'No handle');
    }
    return handle;
  }

  Future<List<OnnxVoice>> voices(String handle) async {
    final voices =
        await _methods.invokeListMethod<Object?>('voices', {'handle': handle});
    return [
      for (final voice in voices ?? const [])
        OnnxVoice.fromMap(voice as Map<Object?, Object?>),
    ];
  }

  /// Speaks [segments] in order and completes when the last one has
  /// finished playing, or once [stop] cuts it off.
  Future<void> speak({
    required String handle,
    required String utteranceId,
    required List<String> segments,
    required String language,
    required String voiceId,
    double speed = 1.0,
    int steps = 5,
  }) =>
      _methods.invokeMethod<void>('speak', {
        'handle': handle,
        'utteranceId': utteranceId,
        'segments': segments,
        'language': language,
        'voiceId': voiceId,
        'speed': speed,
        'steps': steps,
      });

  /// Synthesizes [text] without playing it. With [noiseSeed] the output is
  /// deterministic.
  Future<OnnxSynthesis> synthesize({
    required String handle,
    required String text,
    required String language,
    required String voiceId,
    double speed = 1.0,
    int steps = 5,
    int? noiseSeed,
  }) async {
    final result =
        await _methods.invokeMapMethod<String, Object?>('synthesize', {
      'handle': handle,
      'text': text,
      'language': language,
      'voiceId': voiceId,
      'speed': speed,
      'steps': steps,
      if (noiseSeed != null) 'noiseSeed': noiseSeed,
    });
    if (result == null) {
      throw PlatformException(code: 'synthesis_failed', message: 'No audio');
    }
    return OnnxSynthesis(
      sampleRate: result['sampleRate'] as int,
      pcm: result['pcm'] as Float32List,
    );
  }

  /// Stops the utterance being spoken, if any.
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  /// Releases the model; [handle] can't be used afterwards.
  Future<void> unload(String handle) =>
      _methods.invokeMethod<void>('unload', {'handle': handle});

  /// How much memory the device has, or null where the platform doesn't
  /// say.
  Future<DeviceMemory?> deviceMemory() async {
    try {
      final map =
          await _methods.invokeMapMethod<Object?, Object?>('deviceMemory');
      return map == null ? null : DeviceMemory.fromMap(map);
    } on MissingPluginException {
      return null;
    }
  }

  /// The trim level of each memory warning the native side forwards
  /// (Android only; see `MemoryPressureMonitor`), as a broadcast stream.
  Stream<int> get memoryPressure =>
      _memoryPressure ??= _memoryChannel.receiveBroadcastStream().map((event) =>
          ((event as Map<Object?, Object?>)['level'] as num).toInt());

  /// Events of every utterance, as a broadcast stream.
  Stream<OnnxTtsEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .map((event) => OnnxTtsEvent.fromMap(event as Map<Object?, Object?>))
      .where((event) => event != null)
      .cast<OnnxTtsEvent>();
}
