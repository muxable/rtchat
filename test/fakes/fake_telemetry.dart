import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/telemetry.dart';

/// A [TelemetrySink] that keeps everything sent to it.
class FakeTelemetrySink implements TelemetrySink {
  final events = <(String, Map<String, Object>)>[];
  final keys = <String, Object>{};
  final keyWrites = <String>[];
  final logs = <String>[];
  final nonFatals = <Object>[];

  /// The parameters of every event called [name].
  List<Map<String, Object>> eventsNamed(String name) => [
        for (final (n, parameters) in events)
          if (n == name) parameters,
      ];

  /// Everything sent, as text, to look for what shouldn't be there.
  String get everything => [
        for (final (name, parameters) in events) '$name $parameters',
        for (final MapEntry(:key, :value) in keys.entries) '$key=$value',
        ...logs,
        for (final error in nonFatals) '$error',
      ].join('\n');

  @override
  void event(String name, Map<String, Object> parameters) =>
      events.add((name, parameters));

  @override
  void setKey(String key, Object value) {
    keys[key] = value;
    keyWrites.add(key);
  }

  @override
  void log(String message) => logs.add(message);

  @override
  void recordNonFatal(Object error, StackTrace stack) => nonFatals.add(error);
}

/// A [TtsTelemetry] that records the calls made to it.
class FakeTtsTelemetry implements TtsTelemetry {
  final utterances = <(TtsEngineKind, TtsSystemVoiceReason?)>[];
  final latencies = <Duration>[];
  final loads = <({Duration duration, bool isReload, bool succeeded})>[];
  final engines = <NeuralEngineInfo>[];
  final fallbacks = <NeuralTtsFallback?>[];
  final memory = <DeviceMemory>[];
  final errors = <Object>[];
  final installs = <({
    PackInstallStage stage,
    String packId,
    int sizeBytes,
    Duration? duration,
    String? error,
    bool? overMobileData,
  })>[];
  var flushes = 0;

  List<PackInstallStage> get installStages =>
      [for (final install in installs) install.stage];

  @override
  void utteranceRead(TtsEngineKind engine, {TtsSystemVoiceReason? reason}) =>
      utterances.add((engine, reason));

  @override
  void firstAudio(Duration latency) => latencies.add(latency);

  @override
  void modelLoaded(Duration duration,
          {required bool isReload, required bool succeeded}) =>
      loads.add((duration: duration, isReload: isReload, succeeded: succeeded));

  @override
  void neuralEngineInUse(NeuralEngineInfo info) => engines.add(info);

  @override
  void neuralFallbackChanged(NeuralTtsFallback? reason) =>
      fallbacks.add(reason);

  @override
  void deviceMemory(DeviceMemory memory) => this.memory.add(memory);

  @override
  void recordError(Object error, StackTrace stack) => errors.add(error);

  @override
  void packInstall(PackInstallStage stage,
          {required String packId,
          required int sizeBytes,
          Duration? duration,
          String? error,
          bool? overMobileData}) =>
      installs.add((
        stage: stage,
        packId: packId,
        sizeBytes: sizeBytes,
        duration: duration,
        error: error,
        overMobileData: overMobileData,
      ));

  @override
  void flush() => flushes++;

  @override
  void dispose() {}
}
