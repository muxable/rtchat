import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';

/// Makes a neural engine for an installed voice pack.
typedef NeuralEngineFactory = TtsEngine Function(InstalledVoicePack pack);

/// Gives [tts] a neural engine for each installed voice pack it can speak
/// with, at startup and whenever packs are installed, upgraded or deleted.
/// Without a pack it speaks with the system voices.
///
/// [TtsModel] routes each message to the first of these engines that speaks
/// its language (see [VoiceRouter]), so their order is the order of
/// preference between packs that speak the same language: [choose]'s. An
/// engine whose pack didn't change is kept, with its model loaded.
class NeuralEngineSelector {
  final VoicePackRepository repository;
  final TtsModel tts;
  final NeuralEngineFactory _createEngine;
  final TtsErrorReporter? _reportError;

  StreamSubscription<void>? _changes;
  Future<void> _refreshing = Future.value();
  // the engine of each installed pack, by what identifies its install.
  Map<String, TtsEngine> _engines = {};
  var _isDisposed = false;

  NeuralEngineSelector({
    required this.repository,
    required this.tts,
    NeuralEngineFactory? createEngine,
    TtsErrorReporter? reportError,
  })  : _createEngine = createEngine ?? NeuralTtsEngine.new,
        _reportError = reportError;

  /// Picks the engines now and again whenever the installed packs change.
  Future<void> start() {
    _changes ??= repository.changes.listen((_) => refresh());
    return refresh();
  }

  /// The installed packs to speak with, in order of preference.
  ///
  /// With Supertonic 3 as the only model this is by id; when packs of other
  /// models arrive (#1518), e.g. an English-only pack that sounds better than
  /// a multilingual one, this is where they are ranked ahead of it.
  static List<InstalledVoicePack> choose(
          Iterable<InstalledVoicePack> installed) =>
      installed.where((pack) => NeuralTtsEngine.canSpeak(pack.pack)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  /// Looks at the installed packs again and swaps the engines of packs that
  /// changed.
  Future<void> refresh() =>
      _refreshing = _refreshing.then((_) => _refresh()).catchError(_report);

  Future<void> _refresh() async {
    if (_isDisposed) return;
    final packs = choose((await repository.installedPacks()).values);
    if (_isDisposed) return;
    final engines = <String, TtsEngine>{};
    for (final pack in packs) {
      final key = '${pack.id}@${pack.pack.version}@${pack.directory}@'
          '${pack.installedAt.toIso8601String()}';
      final existing = _engines[key];
      if (existing != null) {
        engines[key] = existing;
        continue;
      }
      try {
        engines[key] = _createEngine(pack);
      } catch (e, st) {
        _report(e, st);
      }
    }
    _engines = engines;
    tts.neuralEngines = engines.values.toList();
  }

  void _report(Object error, StackTrace stack) {
    final report = _reportError;
    if (report != null) {
      report(error, stack);
    }
  }

  /// Stops following pack changes. The engines stay with [tts], which
  /// disposes them.
  void dispose() {
    _isDisposed = true;
    _changes?.cancel();
    _changes = null;
  }
}
