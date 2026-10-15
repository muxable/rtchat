import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts/telemetry.dart';

/// The voice packs for the settings screens: the catalog, what is installed,
/// and the installs in progress, kept up to date as packs come and go.
///
/// Installs belong to the [VoicePackRepository], so they carry on when the
/// settings screens close; this model follows them while it lives.
class VoicePacksModel extends ChangeNotifier {
  /// Null when there is nowhere to keep voice packs (e.g. in tests).
  final VoicePackRepository? repository;

  /// Whether this device can speak with neural voice packs (see
  /// [platformSupportsNeuralVoices]); elsewhere chat is read with the system
  /// voices and the voice pack settings are hidden.
  final bool isSupported;

  /// Told each step of the installs started here: the install funnel.
  final TtsTelemetry telemetry;

  /// How long an install waits for Wi-Fi before it counts as waiting for it
  /// ([PackInstallStage.waitingForWifi]); downloads queue briefly anyway.
  final Duration wifiWaitThreshold;

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
  // when each install started here began, for its duration; kept across a
  // restart over mobile data.
  final _installStarts = <String, Stopwatch>{};
  // installs being restarted over mobile data: their cancellation isn't one.
  final _restarting = <String>{};

  VoicePacksModel(this.repository,
      {bool? isSupported,
      this.telemetry = TtsTelemetry.none,
      this.wifiWaitThreshold = const Duration(seconds: 5)})
      : isSupported =
            repository != null && (isSupported ?? platformSupportsNeuralVoices);

  /// Whether this platform has a native engine for neural voice packs.
  // TODO(#1519): enable on iOS once the native iOS engine is merged.
  static bool get platformSupportsNeuralVoices => Platform.isAndroid;

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
    final isNew = repository.task(pack.id) == null;
    if (isNew) _metered[pack.id] = metered;
    final task = repository.install(pack, allowMetered: metered);
    _statuses[pack.id] = VoicePackStatus.installing;
    if (isNew) _measure(task, metered);
    _follow(task);
    _notify();
    return task;
  }

  /// Restarts the install of [pack], which is waiting for Wi-Fi, so it
  /// downloads over mobile data.
  Future<void> installOverMobileData(VoicePack pack) async {
    final running = task(pack.id);
    if (running != null) {
      _restarting.add(pack.id);
      running.cancel();
      await running.done.then((_) {}, onError: (_) {});
    }
    if (_isDisposed) return;
    install(pack, allowMetered: true);
    _restarting.remove(pack.id);
  }

  /// Cancels the install of pack [id]. An installed version stays.
  void cancel(String id) => task(id)?.cancel();

  /// Deletes pack [id], cancelling its install if one is running.
  Future<void> delete(String id) async {
    final repository = this.repository;
    if (repository == null) return;
    _errors.remove(id);
    final installed = _installed[id];
    await repository.delete(id);
    if (installed != null) {
      telemetry.packInstall(PackInstallStage.deleted,
          packId: id, sizeBytes: installed.sizeOnDisk);
    }
    await refresh();
  }

  /// Tells [telemetry] how the install [task], started here, goes.
  void _measure(VoicePackInstallTask task, bool metered) {
    final pack = task.pack;
    // a restart over mobile data carries on the same install.
    final isRestart = _restarting.contains(pack.id);
    final stopwatch = isRestart
        ? (_installStarts[pack.id] ??= Stopwatch()..start())
        : (_installStarts[pack.id] = Stopwatch()..start());
    void send(PackInstallStage stage, {String? error}) =>
        telemetry.packInstall(stage,
            packId: pack.id,
            sizeBytes: pack.downloadSize,
            duration: stage == PackInstallStage.started ||
                    stage == PackInstallStage.waitingForWifi
                ? null
                : stopwatch.elapsed,
            error: error,
            overMobileData: metered);
    if (!isRestart) send(PackInstallStage.started);

    Timer? waiting;
    var waitedForWifi = false;
    final progress = task.progress.listen((progress) {
      if (progress.phase != VoicePackInstallPhase.waiting) {
        waiting?.cancel();
        waiting = null;
      } else if (!waitedForWifi && waiting == null && waitsForWifi(pack.id)) {
        waiting = Timer(wifiWaitThreshold, () {
          waitedForWifi = true;
          send(PackInstallStage.waitingForWifi);
        });
      }
    }, onError: (Object _) {});
    task.done.then((_) {
      send(PackInstallStage.completed);
    }, onError: (Object e) {
      if (e is VoicePackCancelledException) {
        if (!_restarting.contains(pack.id)) send(PackInstallStage.cancelled);
      } else {
        send(PackInstallStage.failed, error: installErrorType(e));
      }
    }).whenComplete(() {
      waiting?.cancel();
      progress.cancel();
      if (!_restarting.contains(pack.id)) _installStarts.remove(pack.id);
    });
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
