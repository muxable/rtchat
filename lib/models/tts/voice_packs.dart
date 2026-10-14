import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The voice packs for the settings screens: the catalog, what is installed,
/// and the installs in progress, kept up to date as packs come and go.
///
/// Installs belong to the [VoicePackRepository], so they carry on when the
/// settings screens close; this model follows them while it lives.
class VoicePacksModel extends ChangeNotifier {
  /// Null when there is nowhere to keep voice packs (e.g. in tests).
  final VoicePackRepository? repository;

  /// Whether this device can speak with neural voice packs. Only Android
  /// has a native engine so far (iOS is #1517); elsewhere chat is read with
  /// the system voices and the voice pack settings are hidden.
  final bool isSupported;

  List<VoicePack> _packs = const [];
  Map<String, InstalledVoicePack> _installed = const {};
  final _statuses = <String, VoicePackStatus>{};
  final _errors = <String, Object>{};
  final _followed = <VoicePackInstallTask>{};
  // whether each install was allowed to use mobile data.
  final _metered = <String, bool>{};
  var _isLoaded = false;
  Object? _loadError;
  var _allowMobileData = false;
  StreamSubscription<void>? _changes;
  Future<void>? _loading;
  var _isDisposed = false;

  VoicePacksModel(this.repository, {bool? isSupported})
      : isSupported = repository != null && (isSupported ?? Platform.isAndroid);

  /// Reads the catalog and the installed packs, and follows changes to them.
  /// Safe to call more than once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final repository = this.repository;
    if (repository == null || !isSupported) {
      _isLoaded = true;
      _notify();
      return;
    }
    _changes = repository.changes.listen((_) => refresh());
    try {
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
      _loadError = null;
      for (final pack in packs) {
        final task = repository.task(pack.id);
        if (task != null) _follow(task);
      }
    } on Object catch (e) {
      _loadError = e;
    }
    _isLoaded = true;
    _notify();
  }

  /// Whether the catalog and installed packs have been read.
  bool get isLoaded => _isLoaded;

  /// Why the catalog or installed packs couldn't be read, if they couldn't.
  Object? get loadError => _loadError;

  /// The packs that can be installed, in the catalog's order.
  List<VoicePack> get packs => _packs;

  /// The installed packs, by id.
  Map<String, InstalledVoicePack> get installed => _installed;

  bool get hasInstalledPack => _installed.isNotEmpty;

  /// Bytes the installed packs take on disk.
  int get storageUsed =>
      _installed.values.fold(0, (sum, pack) => sum + pack.sizeOnDisk);

  VoicePackStatus status(String id) =>
      _statuses[id] ?? VoicePackStatus.notInstalled;

  /// The install of pack [id] in progress, if any.
  VoicePackInstallTask? task(String id) => repository?.task(id);

  /// Whether the install of pack [id], when it waits, waits for Wi-Fi
  /// rather than its turn.
  bool waitsForWifi(String id) =>
      (repository?.wifiOnly ?? false) && !(_metered[id] ?? false);

  /// Whether a pack is being installed.
  bool get isInstalling => _packs.any((pack) => task(pack.id) != null);

  /// Why the last install of pack [id] failed, until it's tried again.
  Object? error(String id) => _errors[id];

  /// Whether new installs may use mobile data rather than wait for Wi-Fi.
  bool get allowMobileData => _allowMobileData;

  set allowMobileData(bool value) {
    if (_allowMobileData == value) return;
    _allowMobileData = value;
    _notify();
  }

  /// Downloads and installs [pack], or follows its install if one is
  /// running.
  VoicePackInstallTask? install(VoicePack pack, {bool? allowMetered}) {
    final repository = this.repository;
    if (repository == null) return null;
    _errors.remove(pack.id);
    final metered = allowMetered ?? _allowMobileData;
    if (repository.task(pack.id) == null) _metered[pack.id] = metered;
    final task = repository.install(pack, allowMetered: metered);
    _statuses[pack.id] = VoicePackStatus.installing;
    _follow(task);
    _notify();
    return task;
  }

  /// Restarts the install of [pack], which is waiting for Wi-Fi, so it
  /// downloads over mobile data.
  Future<void> installOverMobileData(VoicePack pack) async {
    final running = task(pack.id);
    if (running != null) {
      running.cancel();
      await running.done.then((_) {}, onError: (_) {});
    }
    if (_isDisposed) return;
    install(pack, allowMetered: true);
  }

  /// Cancels the install of pack [id]. An installed version stays.
  void cancel(String id) => task(id)?.cancel();

  /// Deletes pack [id], cancelling its install if one is running.
  Future<void> delete(String id) async {
    final repository = this.repository;
    if (repository == null) return;
    _errors.remove(id);
    await repository.delete(id);
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

  /// The installed packs that speak [language], a BCP-47 tag.
  List<InstalledVoicePack> installedFor(String language) => [
        for (final pack in _installed.values)
          if (LanguageTag.bestMatch(language, pack.pack.languages) != null)
            pack,
      ];

  /// Whether an installed pack speaks [language].
  bool isInstalledFor(String language) => installedFor(language).isNotEmpty;

  /// The first pack in the catalog that speaks [language], if any.
  VoicePack? packFor(String language) {
    for (final pack in _packs) {
      if (LanguageTag.bestMatch(language, pack.languages) != null) return pack;
    }
    return null;
  }

  /// Every language the installed packs speak, as their own tags, without
  /// repeats.
  List<String> get installedLanguages => {
        for (final pack in _installed.values) ...pack.pack.languages,
      }.toList();

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
