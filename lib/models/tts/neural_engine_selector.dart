import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';

/// Makes a neural engine for an installed voice pack.
typedef NeuralEngineFactory = TtsEngine Function(InstalledVoicePack pack);

/// Gives [tts] a neural engine for an installed voice pack, if there is one,
/// at startup and whenever packs are installed, upgraded or deleted. Without
/// a pack, [tts] speaks with the system voices.
///
/// On a device with too little memory
/// ([DeviceMemory.isTooSmallForNeuralTts]), it tells [tts] to read with the
/// system voices instead ([NeuralTtsFallback.lowMemoryDevice]), so no model
/// loads.
class NeuralEngineSelector {
  final VoicePackRepository repository;
  final TtsModel tts;
  final NeuralEngineFactory _createEngine;
  final TtsErrorReporter _reportError;
  final Future<DeviceMemory?> Function() _deviceMemory;

  StreamSubscription<void>? _changes;
  Future<void> _refreshing = Future.value();
  // identifies the install the current engine speaks with.
  String? _installed;
  var _isDisposed = false;

  NeuralEngineSelector({
    required this.repository,
    required this.tts,
    required TtsErrorReporter reportError,
    NeuralEngineFactory? createEngine,
    Future<DeviceMemory?> Function()? deviceMemory,
  })  : _createEngine = createEngine ?? NeuralTtsEngine.new,
        _reportError = reportError,
        _deviceMemory = deviceMemory ?? OnnxTtsPlatform.instance.deviceMemory;

  /// Checks the device's memory, then picks the engine now and again
  /// whenever the installed packs change.
  Future<void> start() {
    if (_changes == null) {
      _changes = repository.changes.listen((_) => refresh());
      _refreshing = _checkDeviceMemory();
    }
    return refresh();
  }

  Future<void> _checkDeviceMemory() async {
    try {
      final memory = await _deviceMemory();
      if (!_isDisposed && memory != null && memory.isTooSmallForNeuralTts) {
        tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      }
    } catch (e, st) {
      _reportError(e, st);
    }
  }

  /// The installed pack to speak with: the first, by id, that a
  /// [NeuralTtsEngine] can speak with.
  static InstalledVoicePack? choose(Iterable<InstalledVoicePack> installed) =>
      (installed.where((pack) => NeuralTtsEngine.canSpeak(pack.pack)).toList()
            ..sort((a, b) => a.id.compareTo(b.id)))
          .firstOrNull;

  /// Looks at the installed packs again and swaps the engine if the pack to
  /// speak with changed.
  Future<void> refresh() => _refreshing =
      _refreshing.then((_) => _refresh()).catchError(_reportError);

  Future<void> _refresh() async {
    if (_isDisposed) return;
    final pack = choose((await repository.installedPacks()).values);
    if (_isDisposed) return;
    final installed = pack == null
        ? null
        : '${pack.id}@${pack.pack.version}@${pack.directory}@'
            '${pack.installedAt.toIso8601String()}';
    if (installed == _installed) return;
    _installed = installed;
    TtsEngine? engine;
    if (pack != null) {
      try {
        engine = _createEngine(pack);
      } catch (e, st) {
        _reportError(e, st);
      }
    }
    tts.neuralEngine = engine;
  }

  /// Stops following pack changes. The engine stays with [tts], which
  /// disposes it.
  void dispose() {
    _isDisposed = true;
    _changes?.cancel();
    _changes = null;
  }
}
