import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';

/// Makes a neural engine for an installed voice pack.
typedef NeuralEngineFactory = TtsEngine Function(InstalledVoicePack pack);

/// Gives [tts] a neural engine for an installed voice pack, if there is one,
/// at startup and whenever packs are installed, upgraded or deleted. Without
/// a pack it speaks with the system voices.
///
/// Picking a pack per language, and a voice per chatter, is left to the
/// voice selection work (#1505): this uses the first pack the engine can
/// speak with, by id.
class NeuralEngineSelector {
  final VoicePackRepository repository;
  final TtsModel tts;
  final NeuralEngineFactory _createEngine;
  final TtsErrorReporter? _reportError;

  StreamSubscription<void>? _changes;
  Future<void> _refreshing = Future.value();
  // identifies the installed pack the current engine speaks with.
  String? _installed;
  var _isDisposed = false;

  NeuralEngineSelector({
    required this.repository,
    required this.tts,
    NeuralEngineFactory? createEngine,
    TtsErrorReporter? reportError,
  })  : _createEngine = createEngine ?? NeuralTtsEngine.new,
        _reportError = reportError;

  /// Picks the engine now and again whenever the installed packs change.
  Future<void> start() {
    _changes ??= repository.changes.listen((_) => refresh());
    return refresh();
  }

  /// The installed pack to speak with, if any.
  static InstalledVoicePack? choose(Iterable<InstalledVoicePack> installed) {
    final usable = installed
        .where((pack) => NeuralTtsEngine.canSpeak(pack.pack))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return usable.firstOrNull;
  }

  /// Looks at the installed packs again and swaps the engine if the pack to
  /// speak with changed.
  Future<void> refresh() =>
      _refreshing = _refreshing.then((_) => _refresh()).catchError(_report);

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
        _report(e, st);
      }
    }
    tts.neuralEngine = engine;
  }

  void _report(Object error, StackTrace stack) {
    final report = _reportError;
    if (report != null) {
      report(error, stack);
    }
  }

  /// Stops following pack changes. The engine stays with [tts], which
  /// disposes it.
  void dispose() {
    _isDisposed = true;
    _changes?.cancel();
    _changes = null;
  }
}
