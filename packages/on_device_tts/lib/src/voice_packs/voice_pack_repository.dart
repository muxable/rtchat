import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'archive_extractor.dart';
import 'bundled_catalog.dart';
import 'download_policy.dart';
import 'file_downloader.dart';
import 'installed_voice_pack.dart';
import 'voice_pack_catalog.dart';
import 'voice_pack_exceptions.dart';

/// Where a pack stands on this device.
enum VoicePackStatus { notInstalled, installing, installed, upgradeAvailable }

/// What an install is doing.
enum VoicePackInstallPhase { downloading, verifying, extracting, done }

/// How far an install has got.
@immutable
class VoicePackProgress {
  final VoicePackInstallPhase phase;

  /// Bytes downloaded so far, over all the pack's files.
  final int downloadedBytes;

  /// The pack's total download size.
  final int totalBytes;

  const VoicePackProgress(this.phase, this.downloadedBytes, this.totalBytes);

  /// The downloaded fraction, from 0 to 1.
  double get fraction =>
      totalBytes == 0 ? 1 : (downloadedBytes / totalBytes).clamp(0.0, 1.0);

  @override
  String toString() =>
      'VoicePackProgress(${phase.name}, $downloadedBytes/$totalBytes)';
}

/// An install in progress, from [VoicePackRepository.install].
class VoicePackInstallTask {
  final VoicePack pack;
  final _progress = StreamController<VoicePackProgress>.broadcast();
  final _done = Completer<InstalledVoicePack>();
  final _cancel = CancellationToken();
  VoicePackProgress _latest;

  VoicePackInstallTask._(this.pack)
      : _latest = VoicePackProgress(
            VoicePackInstallPhase.downloading, 0, pack.downloadSize) {
    // Nobody has to listen to the result; errors still reach those who do.
    _done.future.ignore();
  }

  /// Progress updates; closes when the install ends.
  Stream<VoicePackProgress> get progress => _progress.stream;

  /// The most recent progress.
  VoicePackProgress get latest => _latest;

  /// Completes with the installed pack, or with a [VoicePackException].
  Future<InstalledVoicePack> get done => _done.future;

  bool get isCancelled => _cancel.isCancelled;

  /// Stops the install and deletes what it downloaded. [done] then fails
  /// with a [VoicePackCancelledException]. Any installed version of the
  /// pack stays.
  void cancel() => _cancel.cancel();

  void _emit(VoicePackProgress progress) {
    _latest = progress;
    if (!_progress.isClosed) _progress.add(progress);
  }
}

/// Downloads, installs, upgrades and deletes voice packs.
///
/// Everything lives under [directory], which the app supplies (e.g. from
/// `getApplicationSupportDirectory()`; voice packs are too big to download
/// again whenever the cache is cleared):
///
/// * `packs/<id>/`: installed packs.
/// * `installed.json`: which packs are installed, at which version.
/// * `downloads/`: downloads in progress, kept so a failed one can resume.
/// * `staging/`, `trash/`: where packs are put together and taken apart, so
///   `packs/<id>` is always either the old pack or the new one.
/// * `catalog.json`: the last catalog fetched from [catalogUrl].
class VoicePackRepository {
  /// The directory everything is stored in.
  final Directory directory;

  /// Where to fetch the latest catalog from, or null to only use the
  /// bundled one.
  final Uri? catalogUrl;

  /// Whether downloads wait for an unmetered network unless the caller
  /// allows mobile data for one install.
  final bool wifiOnly;

  /// The app's version, e.g. `1.4.0`, to leave out packs that need a newer
  /// app. Null to not check.
  final String? appVersion;

  final RetryPolicy retryPolicy;

  final http.Client _client;
  final bool _ownsClient;
  final String _bundledCatalogJson;
  final UnmeteredNetworkCheck? _isUnmetered;
  final FreeSpaceCheck? _freeSpace;
  final Future<void> Function(Duration) _sleep;
  final bool _extractInIsolate;

  final _tasks = <String, VoicePackInstallTask>{};
  Future<void> _manifestLock = Future.value();
  Future<VoicePackCatalog>? _catalog;

  /// [client] and [sleep] are for tests. [isUnmeteredNetwork] tells whether
  /// a Wi-Fi-only download may start; without it, Wi-Fi-only downloads need
  /// `allowMetered`. [freeSpace], when given, is checked before
  /// downloading.
  VoicePackRepository({
    required this.directory,
    this.catalogUrl,
    this.wifiOnly = true,
    this.appVersion,
    this.retryPolicy = const RetryPolicy(),
    http.Client? client,
    String bundledCatalogJson = bundledVoicePackCatalogJson,
    UnmeteredNetworkCheck? isUnmeteredNetwork,
    FreeSpaceCheck? freeSpace,
    Future<void> Function(Duration)? sleep,
    bool extractInIsolate = true,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _bundledCatalogJson = bundledCatalogJson,
        _isUnmetered = isUnmeteredNetwork,
        _freeSpace = freeSpace,
        _sleep = sleep ?? Future.delayed,
        _extractInIsolate = extractInIsolate;

  Directory get _packsDir => Directory(p.join(directory.path, 'packs'));
  Directory get _downloadsDir => Directory(p.join(directory.path, 'downloads'));
  Directory get _stagingDir => Directory(p.join(directory.path, 'staging'));
  Directory get _trashDir => Directory(p.join(directory.path, 'trash'));
  File get _manifestFile => File(p.join(directory.path, 'installed.json'));
  File get _catalogFile => File(p.join(directory.path, 'catalog.json'));

  /// The directory pack [id] is or would be installed in.
  Directory packDirectory(String id) => Directory(p.join(_packsDir.path, id));

  /// The catalog the package ships with.
  VoicePackCatalog get bundledCatalog =>
      VoicePackCatalog.parse(_bundledCatalogJson);

  /// The newest catalog among the bundled one, the last one fetched, and,
  /// with [refresh] or on the first call, the one at [catalogUrl].
  Future<VoicePackCatalog> catalog({bool refresh = false}) {
    if (refresh || _catalog == null) _catalog = _loadCatalog();
    return _catalog!;
  }

  Future<VoicePackCatalog> _loadCatalog() async {
    var best = bundledCatalog;
    void consider(VoicePackCatalog candidate) {
      if (candidate.version > best.version) best = candidate;
    }

    try {
      if (await _catalogFile.exists()) {
        consider(VoicePackCatalog.parse(await _catalogFile.readAsString()));
      }
    } on Exception catch (e) {
      debugPrint('ignoring the saved voice pack catalog: $e');
    }
    final url = catalogUrl;
    if (url != null) {
      try {
        final response =
            await _client.get(url).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: url);
        }
        final body = utf8.decode(response.bodyBytes);
        consider(VoicePackCatalog.parse(body));
        await _writeAtomically(_catalogFile, body);
      } on Exception catch (e) {
        debugPrint('using a local voice pack catalog: $e');
      }
    }
    return best;
  }

  /// The catalog's packs that this package and app can install.
  Future<List<VoicePack>> availablePacks({bool refresh = false}) async {
    final version = appVersion;
    return (await catalog(refresh: refresh))
        .packs
        .where((pack) => version == null || pack.isCompatibleWith(version))
        .toList();
  }

  /// The installed packs, by id.
  Future<Map<String, InstalledVoicePack>> installedPacks() async {
    final manifest = await _readManifest();
    final installed = <String, InstalledVoicePack>{};
    for (final MapEntry(:key, :value) in manifest.entries) {
      try {
        final dir = packDirectory(key);
        if (!await dir.exists()) continue;
        installed[key] = InstalledVoicePack.fromJson(
            value as Map<String, Object?>, dir.path);
      } on Object catch (e) {
        debugPrint('ignoring installed voice pack $key: $e');
      }
    }
    return installed;
  }

  /// The installed pack [id], or null.
  Future<InstalledVoicePack?> installedPack(String id) async =>
      (await installedPacks())[id];

  /// Where [pack] stands on this device.
  Future<VoicePackStatus> status(VoicePack pack) async {
    if (_tasks.containsKey(pack.id)) return VoicePackStatus.installing;
    final installed = await installedPack(pack.id);
    if (installed == null) return VoicePackStatus.notInstalled;
    return installed.isOutdatedBy(pack)
        ? VoicePackStatus.upgradeAvailable
        : VoicePackStatus.installed;
  }

  /// The installed packs that [catalog] has a newer version of.
  Future<List<VoicePack>> upgrades({VoicePackCatalog? catalog}) async {
    final latest = catalog ?? await this.catalog();
    final installed = await installedPacks();
    return [
      for (final pack in latest.packs)
        if (installed[pack.id]?.isOutdatedBy(pack) ?? false) pack,
    ];
  }

  /// The install of pack [id] in progress, or null.
  VoicePackInstallTask? task(String id) => _tasks[id];

  /// Downloads, verifies and installs [pack], replacing any installed
  /// version once the new one is ready. Returns the install already in
  /// progress for the pack if there is one.
  ///
  /// With [wifiOnly], the download only starts on an unmetered network
  /// unless [allowMetered].
  VoicePackInstallTask install(VoicePack pack, {bool allowMetered = false}) {
    final running = _tasks[pack.id];
    if (running != null) return running;
    final task = VoicePackInstallTask._(pack);
    _tasks[pack.id] = task;
    () async {
      try {
        final installed = await _install(task, allowMetered);
        task._emit(VoicePackProgress(
            VoicePackInstallPhase.done, pack.downloadSize, pack.downloadSize));
        task._done.complete(installed);
      } on Object catch (e, stack) {
        if (task.isCancelled && e is! VoicePackCancelledException) {
          task._done.completeError(const VoicePackCancelledException(), stack);
        } else {
          task._done.completeError(e, stack);
        }
      } finally {
        _tasks.remove(pack.id);
        await task._progress.close();
      }
    }();
    return task;
  }

  Future<InstalledVoicePack> _install(
      VoicePackInstallTask task, bool allowMetered) async {
    final pack = task.pack;
    final cancel = task._cancel;
    if (!pack.isSupported) {
      throw VoicePackUnsupportedException(
          '${pack.id} has an unsupported model type or archive format');
    }
    final version = appVersion;
    if (version != null && !pack.isCompatibleWith(version)) {
      throw VoicePackUnsupportedException(
          '${pack.id} needs app version ${pack.minAppVersion}');
    }
    if (wifiOnly && !allowMetered) {
      final check = _isUnmetered;
      if (check == null || !await check()) {
        throw const VoicePackDownloadBlockedException(
            'voice packs only download on Wi-Fi');
      }
    }
    await _downloadsDir.create(recursive: true);
    await _checkFreeSpace(pack);

    final staging = Directory(p.join(_stagingDir.path, pack.id));
    final downloads = [
      for (final file in pack.files)
        File(p.join(_downloadsDir.path, '${file.sha256}.part')),
    ];
    try {
      // Download everything first, so a failure leaves nothing half done.
      final done = List.filled(pack.files.length, 0);
      void report(VoicePackInstallPhase phase) => task._emit(VoicePackProgress(
          phase, done.fold(0, (a, b) => a + b), pack.downloadSize));
      for (var i = 0; i < pack.files.length; i++) {
        await downloadFile(
          client: _client,
          file: pack.files[i],
          partFile: downloads[i],
          cancel: cancel,
          retry: retryPolicy,
          sleep: _sleep,
          onProgress: (bytes) {
            done[i] = bytes;
            report(bytes == pack.files[i].size
                ? VoicePackInstallPhase.verifying
                : VoicePackInstallPhase.downloading);
          },
        );
      }

      cancel.throwIfCancelled();
      report(VoicePackInstallPhase.extracting);
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);
      for (var i = 0; i < pack.files.length; i++) {
        cancel.throwIfCancelled();
        final file = pack.files[i];
        final target = p.join(staging.path, file.path);
        final archive = file.archive;
        if (archive == null) {
          await Directory(p.dirname(target)).create(recursive: true);
          await downloads[i].rename(target);
        } else {
          await _extract(
            archivePath: downloads[i].path,
            type: archive,
            destination: target,
            scratchPath: p.join(_stagingDir.path, '${pack.id}.tar'),
            stripComponents: file.stripComponents,
            inIsolate: _extractInIsolate,
          );
          await downloads[i].delete();
        }
      }
      cancel.throwIfCancelled();

      final installed = InstalledVoicePack(
        pack: pack,
        directory: packDirectory(pack.id).path,
        catalogVersion: (await catalog()).version,
        sizeOnDisk: await _sizeOf(staging),
        installedAt: DateTime.now(),
      );
      await _locked(() async {
        await _swapIn(staging, packDirectory(pack.id));
        final manifest = await _readManifest();
        manifest[pack.id] = installed.toJson();
        await _writeManifest(manifest);
      });
      return installed;
    } on VoicePackCancelledException {
      for (final download in downloads) {
        await _deleteQuietly(download);
      }
      rethrow;
    } on VoicePackArchiveException {
      // The archive matched its checksum, so downloading it again won't help.
      for (final download in downloads) {
        await _deleteQuietly(download);
      }
      rethrow;
    } finally {
      await _deleteQuietly(staging);
    }
  }

  // Static so the closure sent to the isolate captures only its arguments.
  static Future<void> _extract({
    required String archivePath,
    required VoicePackArchiveType type,
    required String destination,
    required String scratchPath,
    required int stripComponents,
    required bool inIsolate,
  }) async {
    void extract() => extractArchive(
          archivePath: archivePath,
          type: type,
          destination: destination,
          scratchPath: scratchPath,
          stripComponents: stripComponents,
        );
    if (inIsolate) {
      await Isolate.run(extract);
    } else {
      extract();
    }
  }

  Future<void> _checkFreeSpace(VoicePack pack) async {
    final freeSpace = _freeSpace;
    if (freeSpace == null) return;
    final available = await freeSpace(directory.path);
    if (available == null) return;
    var required = 0;
    for (final file in pack.files) {
      final part = File(p.join(_downloadsDir.path, '${file.sha256}.part'));
      final have = await part.exists() ? await part.length() : 0;
      // An archive also needs room for the decompressed tar and the
      // extracted files; this guesses each at twice the download.
      required +=
          (file.size - have) + (file.archive == null ? 0 : 4 * file.size);
    }
    if (available < required) {
      throw VoicePackInsufficientSpaceException(
          '${pack.id} needs $required bytes, $available are free',
          required,
          available);
    }
  }

  /// Puts [staging] at [target], keeping the old [target] until the new one
  /// is in place.
  Future<void> _swapIn(Directory staging, Directory target) async {
    await target.parent.create(recursive: true);
    Directory? old;
    if (await target.exists()) {
      await _trashDir.create(recursive: true);
      old = await target.rename(p.join(_trashDir.path,
          '${p.basename(target.path)}-${DateTime.now().microsecondsSinceEpoch}'));
    }
    try {
      await staging.rename(target.path);
    } on FileSystemException {
      if (old != null) await old.rename(target.path);
      rethrow;
    }
    if (old != null) await _deleteQuietly(old);
  }

  /// Deletes pack [id], cancelling its install if one is running.
  Future<void> delete(String id) async {
    final running = _tasks[id];
    if (running != null) {
      running.cancel();
      await running.done.then((_) {}, onError: (_) {});
    }
    await _locked(() async {
      final manifest = await _readManifest();
      if (manifest.remove(id) != null) await _writeManifest(manifest);
      final dir = packDirectory(id);
      if (await dir.exists()) {
        await _trashDir.create(recursive: true);
        final trashed = await dir.rename(p.join(
            _trashDir.path, '$id-${DateTime.now().microsecondsSinceEpoch}'));
        await _deleteQuietly(trashed);
      }
    });
  }

  /// Deletes leftovers of installs that were interrupted, e.g. by the app
  /// being killed. Downloads that can still resume are kept unless [all].
  Future<void> cleanUp({bool all = false}) async {
    if (_tasks.isNotEmpty) return;
    await _deleteQuietly(_stagingDir);
    await _deleteQuietly(_trashDir);
    if (all) await _deleteQuietly(_downloadsDir);
  }

  /// Cancels running installs and closes the HTTP client if the repository
  /// created it.
  Future<void> dispose() async {
    final running = _tasks.values.toList();
    for (final task in running) {
      task.cancel();
    }
    for (final task in running) {
      await task.done.then((_) {}, onError: (_) {});
    }
    if (_ownsClient) _client.close();
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _manifestLock.then((_) => action());
    _manifestLock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Map<String, Object?>> _readManifest() async {
    try {
      final json = jsonDecode(await _manifestFile.readAsString());
      if (json is Map<String, Object?> &&
          json['packs'] is Map<String, Object?>) {
        return Map.of(json['packs'] as Map<String, Object?>);
      }
    } on PathNotFoundException {
      return {};
    } on Exception catch (e) {
      debugPrint('the voice pack manifest is unreadable: $e');
    }
    return {};
  }

  Future<void> _writeManifest(Map<String, Object?> packs) =>
      _writeAtomically(_manifestFile, jsonEncode({'packs': packs}));

  static Future<void> _writeAtomically(File file, String contents) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(contents, flush: true);
    await temp.rename(file.path);
  }

  static Future<int> _sizeOf(Directory dir) async {
    var size = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) size += await entity.length();
    }
    return size;
  }

  static Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // Already gone, or will be cleaned up later.
    }
  }
}
