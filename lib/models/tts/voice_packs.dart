import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The voice packs for the settings screens: the catalog and what is
/// installed, kept up to date as packs come and go.
class VoicePacksModel extends ChangeNotifier {
  /// Null when there is nowhere to keep voice packs (e.g. in tests).
  final VoicePackRepository? repository;

  /// Whether this device reads chat with neural voice packs; elsewhere the
  /// voice pack settings are hidden.
  final bool isSupported;

  List<VoicePack> _packs = const [];
  Map<String, InstalledVoicePack> _installed = const {};
  StreamSubscription<void>? _changes;
  var _isDisposed = false;

  VoicePacksModel(this.repository, {bool? isSupported})
      : isSupported =
            repository != null && (isSupported ?? platformSupportsNeuralVoices);

  /// Whether this platform reads chat with neural voice packs.
  // TODO(#1499): enable on iOS.
  static bool get platformSupportsNeuralVoices => Platform.isAndroid;

  /// Reads the catalog and the installed packs, and follows changes to them.
  Future<void> load() async {
    final repository = this.repository;
    if (repository == null || !isSupported || _isDisposed) return;
    _changes ??= repository.changes.listen((_) => refresh());
    await refresh();
  }

  /// Reads the catalog and the installed packs again.
  Future<void> refresh() async {
    final repository = this.repository;
    if (repository == null || _isDisposed) return;
    try {
      final packs = await repository.availablePacks();
      final installed = await repository.installedPacks();
      if (_isDisposed) return;
      _packs = packs;
      _installed = installed;
    } on Object catch (e) {
      debugPrint('could not read the voice packs: $e');
    }
    _notify();
  }

  /// The packs that can be installed, in the catalog's order.
  List<VoicePack> get packs => _packs;

  /// The installed packs, by id.
  Map<String, InstalledVoicePack> get installed => _installed;

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _changes?.cancel();
    super.dispose();
  }
}
