import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The voice packs for the settings screens: the catalog, what is installed
/// and the installs in progress, kept up to date as packs come and go.
///
/// Installs belong to the [VoicePackRepository], so they carry on when the
/// settings screens close.
class VoicePacksModel extends ChangeNotifier {
  /// Null when there is nowhere to keep voice packs (e.g. in tests).
  final VoicePackRepository? repository;

  /// Whether this device reads chat with neural voice packs; elsewhere the
  /// voice pack settings are hidden.
  final bool isSupported;

  List<VoicePack> _packs = const [];
  Map<String, InstalledVoicePack> _installed = const {};
  final _statuses = <String, VoicePackStatus>{};
  final _errors = <String, Object>{};
  final _followed = <VoicePackInstallTask>{};
  // the installs allowed to use mobile data rather than wait for Wi-Fi.
  final _metered = <String>{};
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
    try {
      // leftovers of installs that didn't finish.
      await repository.cleanUp();
    } on Object catch (e) {
      debugPrint('could not clean up voice packs: $e');
    }
    await refresh();
  }

  /// Reads the catalog, the installed packs and their statuses again.
  Future<void> refresh() async {
    final repository = this.repository;
    if (repository == null || _isDisposed) return;
    try {
      final packs = await repository.availablePacks();
      final installed = await repository.installedPacks();
      final statuses = {
        for (final pack in packs) pack.id: await repository.status(pack),
      };
      if (_isDisposed) return;
      _packs = packs;
      _installed = installed;
      _statuses
        ..clear()
        ..addAll(statuses);
      for (final pack in packs) {
        if (repository.task(pack.id) case final task?) _follow(task);
      }
    } on Object catch (e) {
      debugPrint('could not read the voice packs: $e');
    }
    _notify();
  }

  /// The packs that can be installed, in the catalog's order.
  List<VoicePack> get packs => _packs;

  /// The installed packs, by id.
  Map<String, InstalledVoicePack> get installed => _installed;

  VoicePackStatus status(String id) =>
      _statuses[id] ?? VoicePackStatus.notInstalled;

  /// The install of pack [id] in progress, if any.
  VoicePackInstallTask? task(String id) => repository?.task(id);

  /// Whether the install of pack [id], while it waits, waits for Wi-Fi.
  bool waitsForWifi(String id) =>
      (repository?.wifiOnly ?? false) && !_metered.contains(id);

  /// Why the last install of pack [id] failed, until it's tried again.
  Object? error(String id) => _errors[id];

  /// Downloads and installs [pack] over Wi-Fi, or over any network with
  /// [allowMetered], or follows its install if one is running.
  void install(VoicePack pack, {bool allowMetered = false}) {
    final repository = this.repository;
    if (repository == null) return;
    _errors.remove(pack.id);
    if (repository.task(pack.id) == null) {
      allowMetered ? _metered.add(pack.id) : _metered.remove(pack.id);
    }
    _statuses[pack.id] = VoicePackStatus.installing;
    _follow(repository.install(pack, allowMetered: allowMetered));
    _notify();
  }

  /// Restarts the install of [pack], which waits for Wi-Fi, over mobile
  /// data.
  Future<void> installOverMobileData(VoicePack pack) async {
    if (task(pack.id) case final running?) {
      running.cancel();
      await running.done.then((_) {}, onError: (_) {});
    }
    if (!_isDisposed) install(pack, allowMetered: true);
  }

  /// Cancels the install of pack [id]; an installed version stays.
  void cancel(String id) => task(id)?.cancel();

  /// Deletes pack [id], cancelling its install if one is running.
  Future<void> delete(String id) async {
    _errors.remove(id);
    await repository?.delete(id);
    await refresh();
  }

  void _follow(VoicePackInstallTask task) {
    if (!_followed.add(task)) return;
    task.done.then((_) {}, onError: (Object e) {
      if (e is! VoicePackCancelledException) _errors[task.pack.id] = e;
    }).whenComplete(() {
      _followed.remove(task);
      return refresh();
    });
  }

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
