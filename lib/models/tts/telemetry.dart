import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';

/// Which engine read a message.
enum TtsEngineKind { neural, system }

/// Why a message was read with the system voice.
enum TtsSystemVoiceReason {
  /// No neural voice pack is installed (or none can be spoken with): not a
  /// fallback, the user hasn't opted in.
  noVoicePack,

  /// The installed voice packs don't speak the message's language.
  unsupportedLanguage,

  /// The neural engine failed to read this message.
  neuralError,

  /// The device has too little memory for neural voices
  /// ([NeuralTtsFallback.lowMemoryDevice]).
  lowMemory,

  /// A neural model failed to load ([NeuralTtsFallback.loadFailed]).
  loadFailed;

  /// The reason for messages read while [fallback] is in force.
  static TtsSystemVoiceReason forFallback(NeuralTtsFallback fallback) =>
      switch (fallback) {
        NeuralTtsFallback.lowMemoryDevice => lowMemory,
        NeuralTtsFallback.loadFailed => loadFailed,
      };
}

/// The stages of a voice pack install, for an install funnel.
enum PackInstallStage {
  started,

  /// The download waited for Wi-Fi for a while (not just a moment).
  waitingForWifi,
  completed,
  failed,
  cancelled,
  deleted,
}

/// What identifies a neural engine's setup, for the Crashlytics keys.
@immutable
class NeuralEngineInfo {
  final String packId;
  final String modelType;
  final String provider;
  final int threads;

  const NeuralEngineInfo({
    required this.packId,
    required this.modelType,
    required this.provider,
    required this.threads,
  });

  factory NeuralEngineInfo.of(NeuralTtsEngine engine) => NeuralEngineInfo(
        packId: engine.pack.id,
        modelType: engine.pack.pack.modelTypeName,
        provider: engine.provider.name,
        threads: engine.numThreads,
      );

  @override
  bool operator ==(Object other) =>
      other is NeuralEngineInfo &&
      other.packId == packId &&
      other.modelType == modelType &&
      other.provider == provider &&
      other.threads == threads;

  @override
  int get hashCode => Object.hash(packId, modelType, provider, threads);
}

/// Measures how text to speech performs, for dashboards and crash reports.
///
/// Callers only pass enums, durations, sizes and catalog ids: never message
/// text, usernames or channel names, so no implementation can leak them.
abstract class TtsTelemetry {
  /// Records nothing.
  static const TtsTelemetry none = _NoTtsTelemetry();

  /// A message was read by [engine]; [reason] says why it was the system
  /// voice.
  void utteranceRead(TtsEngineKind engine, {TtsSystemVoiceReason? reason});

  /// A neural utterance played its first audio [latency] after the native
  /// engine was asked to speak it (not counting a model load).
  void firstAudio(Duration latency);

  /// A neural model loaded (or failed to) in [duration]; [isReload] when the
  /// same engine had loaded it before, e.g. after an idle release.
  void modelLoaded(Duration duration,
      {required bool isReload, required bool succeeded});

  /// The neural engine about to speak.
  void neuralEngineInUse(NeuralEngineInfo info);

  /// Neural voices were turned off for the session for [reason], or back
  /// on when null.
  void neuralFallbackChanged(NeuralTtsFallback? reason);

  /// The device's memory, once at startup.
  void deviceMemory(DeviceMemory memory);

  /// An error that didn't stop speech; see [TtsErrorReporter].
  void recordError(Object error, StackTrace stack);

  /// A step of the install of pack [packId] ([sizeBytes]: its download
  /// size, or its size on disk once [PackInstallStage.deleted]).
  void packInstall(
    PackInstallStage stage, {
    required String packId,
    required int sizeBytes,
    Duration? duration,
    String? error,
    bool? overMobileData,
  });

  /// Sends what was gathered so far, e.g. as the app goes to the background.
  void flush();

  void dispose();
}

class _NoTtsTelemetry implements TtsTelemetry {
  const _NoTtsTelemetry();

  @override
  void utteranceRead(TtsEngineKind engine, {TtsSystemVoiceReason? reason}) {}

  @override
  void firstAudio(Duration latency) {}

  @override
  void modelLoaded(Duration duration,
      {required bool isReload, required bool succeeded}) {}

  @override
  void neuralEngineInUse(NeuralEngineInfo info) {}

  @override
  void neuralFallbackChanged(NeuralTtsFallback? reason) {}

  @override
  void deviceMemory(DeviceMemory memory) {}

  @override
  void recordError(Object error, StackTrace stack) {}

  @override
  void packInstall(PackInstallStage stage,
      {required String packId,
      required int sizeBytes,
      Duration? duration,
      String? error,
      bool? overMobileData}) {}

  @override
  void flush() {}

  @override
  void dispose() {}
}

/// Where [SessionTtsTelemetry] sends what it gathered.
abstract interface class TelemetrySink {
  /// An analytics event; [parameters] are strings and numbers.
  void event(String name, Map<String, Object> parameters);

  /// A key attached to crash reports.
  void setKey(String key, Object value);

  /// A breadcrumb attached to the next crash report.
  void log(String message);

  /// A non-fatal error report.
  void recordNonFatal(Object error, StackTrace stack);
}

/// Sends events to Firebase Analytics, and keys, breadcrumbs and non-fatal
/// errors to Crashlytics. Failures to send are ignored: telemetry never
/// gets in the way of speech.
class FirebaseTelemetrySink implements TelemetrySink {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  FirebaseTelemetrySink(
      {FirebaseAnalytics? analytics, FirebaseCrashlytics? crashlytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance,
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  void event(String name, Map<String, Object> parameters) => _analytics
      .logEvent(name: name, parameters: parameters)
      .catchError((Object e) => debugPrint('tts telemetry: $e'));

  @override
  void setKey(String key, Object value) => _crashlytics
      .setCustomKey(key, value)
      .catchError((Object e) => debugPrint('tts telemetry: $e'));

  @override
  void log(String message) => _crashlytics
      .log(message)
      .catchError((Object e) => debugPrint('tts telemetry: $e'));

  @override
  void recordNonFatal(Object error, StackTrace stack) => _crashlytics
      .recordError(error, stack, fatal: false)
      .catchError((Object e) => debugPrint('tts telemetry: $e'));
}

/// A text to speech error as it is reported: its type, and a detail only for
/// errors that can't contain chat (loading a model), so the text being read
/// never reaches a crash report.
class TtsErrorReport implements Exception {
  /// The error's type, with a platform error's code, e.g.
  /// `PlatformException(speak_failed)`.
  final String type;
  final String? detail;

  const TtsErrorReport(this.type, [this.detail]);

  factory TtsErrorReport.of(Object error) {
    final type = errorType(error);
    if (error is NeuralTtsLoadException) {
      return TtsErrorReport(type, _truncate(error.message, 200));
    }
    return TtsErrorReport(type);
  }

  /// [error]'s type, with a platform error's code.
  static String errorType(Object error) => error is PlatformException
      ? 'PlatformException(${error.code})'
      : error.runtimeType.toString();

  static String _truncate(String text, int length) =>
      text.length <= length ? text : text.substring(0, length);

  @override
  String toString() => detail == null ? type : '$type: $detail';
}

/// The kind of [error] an install failed with, for the install funnel.
String installErrorType(Object error) => switch (error) {
      VoicePackInsufficientSpaceException() => 'no_space',
      VoicePackDownloadException(:final statusCode) =>
        statusCode == null ? 'download' : 'download_http_$statusCode',
      VoicePackChecksumException() => 'checksum',
      VoicePackArchiveException() => 'archive',
      VoicePackUnsupportedException() => 'unsupported',
      VoicePackCancelledException() => 'cancelled',
      _ => 'other',
    };

/// The [p]th percentile (0 to 100) of [sorted], by nearest rank, or null if
/// it's empty.
@visibleForTesting
int? percentile(List<int> sorted, int p) {
  if (sorted.isEmpty) return null;
  final rank = (p / 100 * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

/// Gathers text to speech telemetry for a session and sends it to a
/// [TelemetrySink]:
///
/// * Crashlytics keys, set when they change: `tts_engine`, `tts_pack_id`,
///   `tts_model_type`, `tts_provider`, `tts_threads`, `tts_neural_fallback`
///   and `device_total_mem_mb`.
/// * Errors as non-fatal reports, at most [maxErrorsPerType] of each type
///   per session (see [TtsErrorReport]); the rest are only counted.
/// * Per-utterance numbers aggregated into a `tts_summary` event (and a
///   breadcrumb) every [summaryInterval] and on [flush]: how many messages
///   each engine read and why the system voice did, time to first audio
///   (p50/p90 of up to [maxLatencySamples] sampled utterances), model loads,
///   reloads and load times, and errors.
/// * One `tts_neural_fallback` event per reason per session.
/// * The install funnel as `tts_pack_<stage>` events.
class SessionTtsTelemetry implements TtsTelemetry {
  final TelemetrySink sink;
  final Duration? summaryInterval;
  final int maxErrorsPerType;
  final int maxLatencySamples;
  final Random _random;

  final _keys = <String, Object>{};
  final _errorCounts = <String, int>{};
  final _fallbacksSent = <NeuralTtsFallback>{};
  Timer? _timer;

  // the current summary window.
  var _neural = 0;
  final _system = <TtsSystemVoiceReason, int>{};
  final _latencies = <int>[];
  var _latencyCount = 0;
  var _loads = 0;
  var _reloads = 0;
  var _loadFailures = 0;
  final _loadTimes = <int>[];
  var _errors = 0;
  var _errorsDropped = 0;

  SessionTtsTelemetry(
    this.sink, {
    this.summaryInterval = const Duration(minutes: 15),
    this.maxErrorsPerType = 3,
    this.maxLatencySamples = 200,
    Random? random,
  }) : _random = random ?? Random();

  void _setKey(String key, Object value) {
    if (_keys[key] == value) return;
    _keys[key] = value;
    sink.setKey(key, value);
  }

  void _touch() {
    final interval = summaryInterval;
    if (interval != null) _timer ??= Timer.periodic(interval, (_) => flush());
  }

  @override
  void utteranceRead(TtsEngineKind engine, {TtsSystemVoiceReason? reason}) {
    _touch();
    _setKey('tts_engine', engine.name);
    if (engine == TtsEngineKind.neural) {
      _neural++;
    } else {
      final why = reason ?? TtsSystemVoiceReason.noVoicePack;
      _system[why] = (_system[why] ?? 0) + 1;
    }
  }

  @override
  void firstAudio(Duration latency) {
    _touch();
    // reservoir sampling: a uniform sample of the window's utterances in
    // bounded memory.
    final ms = latency.inMilliseconds;
    _latencyCount++;
    if (_latencies.length < maxLatencySamples) {
      _latencies.add(ms);
    } else {
      final i = _random.nextInt(_latencyCount);
      if (i < maxLatencySamples) _latencies[i] = ms;
    }
  }

  @override
  void modelLoaded(Duration duration,
      {required bool isReload, required bool succeeded}) {
    _touch();
    if (!succeeded) {
      _loadFailures++;
      return;
    }
    _loads++;
    if (isReload) _reloads++;
    if (_loadTimes.length < maxLatencySamples) {
      _loadTimes.add(duration.inMilliseconds);
    }
  }

  @override
  void neuralEngineInUse(NeuralEngineInfo info) {
    _setKey('tts_pack_id', info.packId);
    _setKey('tts_model_type', info.modelType);
    _setKey('tts_provider', info.provider);
    _setKey('tts_threads', info.threads);
  }

  @override
  void neuralFallbackChanged(NeuralTtsFallback? reason) {
    _setKey('tts_neural_fallback', reason?.name ?? 'none');
    if (reason != null && _fallbacksSent.add(reason)) {
      sink.event('tts_neural_fallback', {'reason': reason.name});
      sink.log('tts: neural voices off (${reason.name})');
    }
  }

  @override
  void deviceMemory(DeviceMemory memory) {
    _setKey('device_total_mem_mb', memory.totalBytes >> 20);
  }

  @override
  void recordError(Object error, StackTrace stack) {
    _touch();
    _errors++;
    final report = TtsErrorReport.of(error);
    final count = (_errorCounts[report.type] ?? 0) + 1;
    _errorCounts[report.type] = count;
    if (count > maxErrorsPerType) {
      _errorsDropped++;
      return;
    }
    sink.recordNonFatal(report, stack);
  }

  @override
  void packInstall(PackInstallStage stage,
      {required String packId,
      required int sizeBytes,
      Duration? duration,
      String? error,
      bool? overMobileData}) {
    final name = switch (stage) {
      PackInstallStage.started => 'tts_pack_install_started',
      PackInstallStage.waitingForWifi => 'tts_pack_install_waiting_wifi',
      PackInstallStage.completed => 'tts_pack_install_completed',
      PackInstallStage.failed => 'tts_pack_install_failed',
      PackInstallStage.cancelled => 'tts_pack_install_cancelled',
      PackInstallStage.deleted => 'tts_pack_deleted',
    };
    sink.event(name, {
      'pack_id': packId,
      'size_mb': sizeBytes ~/ 1000000,
      if (duration != null) 'duration_s': duration.inSeconds,
      if (error != null) 'error': error,
      if (overMobileData != null) 'mobile_data': overMobileData ? 1 : 0,
    });
    sink.log('tts: pack $packId ${stage.name}'
        '${error == null ? '' : ' ($error)'}');
  }

  /// The summary of the current window, or null if nothing happened.
  @visibleForTesting
  Map<String, Object>? summary() {
    final system = _system.values.fold(0, (a, b) => a + b);
    final total = _neural + system;
    if (total == 0 &&
        _loads == 0 &&
        _loadFailures == 0 &&
        _errors == 0 &&
        _latencyCount == 0) {
      return null;
    }
    final latencies = List.of(_latencies)..sort();
    final loadTimes = List.of(_loadTimes)..sort();
    int count(TtsSystemVoiceReason reason) => _system[reason] ?? 0;
    return {
      'utterances': total,
      'neural': _neural,
      'system': system,
      'neural_pct': total == 0 ? 0 : (_neural * 100 / total).round(),
      'system_no_pack': count(TtsSystemVoiceReason.noVoicePack),
      'fallback_unsupported_language':
          count(TtsSystemVoiceReason.unsupportedLanguage),
      'fallback_neural_error': count(TtsSystemVoiceReason.neuralError),
      'fallback_low_memory': count(TtsSystemVoiceReason.lowMemory),
      'fallback_load_failed': count(TtsSystemVoiceReason.loadFailed),
      'first_audio_count': _latencyCount,
      if (latencies.isNotEmpty) ...{
        'first_audio_p50_ms': percentile(latencies, 50)!,
        'first_audio_p90_ms': percentile(latencies, 90)!,
      },
      'model_loads': _loads,
      'model_reloads': _reloads,
      'model_load_failures': _loadFailures,
      if (loadTimes.isNotEmpty) ...{
        'model_load_p50_ms': percentile(loadTimes, 50)!,
        'model_load_max_ms': loadTimes.last,
      },
      'errors': _errors,
      'errors_not_reported': _errorsDropped,
    };
  }

  @override
  void flush() {
    final summary = this.summary();
    if (summary == null) return;
    sink.event('tts_summary', summary);
    sink.log(
        'tts summary: ${summary.entries.map((e) => '${e.key}=${e.value}').join(' ')}');
    _neural = 0;
    _system.clear();
    _latencies.clear();
    _latencyCount = 0;
    _loads = 0;
    _reloads = 0;
    _loadFailures = 0;
    _loadTimes.clear();
    _errors = 0;
    _errorsDropped = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    flush();
  }
}
