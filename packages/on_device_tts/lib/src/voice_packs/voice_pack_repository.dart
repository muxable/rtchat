import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'archive_extractor.dart';
import 'bundled_catalog.dart';
import 'download_policy.dart';
import 'installed_voice_pack.dart';
import 'pack_downloader.dart';
import 'voice_pack_catalog.dart';
import 'voice_pack_exceptions.dart';

/// Where a pack stands on this device.
enum VoicePackStatus { notInstalled, installing, installed, upgradeAvailable }

/// What an install is doing.
enum VoicePackInstallPhase {
  /// Queued: waiting for Wi-Fi, for the system to run it, or to retry.
  waiting,
  downloading,
  verifying,
  extracting,
  done,
}

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
  final _cancel = Completer<void>();
  VoicePackProgress _latest;
  String? _downloadId;

  VoicePackInstallTask._(this.pack)
      : _latest = VoicePackProgress(
            VoicePackInstallPhase.waiting, 0, pack.downloadSize) {
    // Nobody has to listen to the result; errors still reach those who do.
    _done.future.ignore();
  }

  /// Progress updates; closes when the install ends.
  Stream<VoicePackProgress> get progress => _progress.stream;

  /// The most recent progress.
  VoicePackProgress get latest => _latest;

  /// Completes with the installed pack, or with a [VoicePackException].
  Future<InstalledVoicePack> get done => _done.future;

  bool get isCancelled => _cancel.isCompleted;

  /// Stops the install, cancelling its download, and deletes what it
  /// downloaded. [done] then fails with a [VoicePackCancelledException].
  /// Any installed version of the pack stays.
  void cancel() {
    if (!_cancel.isCompleted) _cancel.complete();
  }

  void _throwIfCancelled() {
    if (isCancelled) throw const VoicePackCancelledException();
  }

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
/// * `downloads/`: finished downloads not yet installed. A download that
///   finished while the app wasn't running is used by the next install.
/// * `staging/`, `trash/`: where packs are put together and taken apart, so
///   `packs/<id>` is always either the old pack or the new one.
/// * `catalog.json`: the last catalog fetched from [catalogUrl].
class VoicePackRepository {
  /// The directory everything is stored in.
  final Directory directory;

  /// Where to fetch the latest catalog from, or null to only use the
  /// bundled one.
  final Uri? catalogUrl;

  /// Whether downloads wait for Wi-Fi unless the caller allows mobile data
  /// for one install.
  final bool wifiOnly;

  /// The app's version, e.g. `1.4.0`, to leave out packs that need a newer
  /// app. Null to not check.
  final String? appVersion;

  final http.Client _client;
  final bool _ownsClient;
  final PackDownloader _downloader;
  final String _bundledCatalogJson;
  final FreeSpaceCheck? _freeSpace;
  final bool _extractInIsolate;

  final _tasks = <String, VoicePackInstallTask>{};
  final _changes = StreamController<void>.broadcast();
  Future<void> _manifestLock = Future.value();
  Future<VoicePackCatalog>? _catalog;
  Future<void>? _started;

  /// [client] fetches the catalog. Files download in the background with
  /// [BackgroundPackDownloader] unless [downloader] says otherwise, which is
  /// for tests. [freeSpace], when given, is checked before downloading.
  VoicePackRepository({
    required this.directory,
    this.catalogUrl,
    this.wifiOnly = true,
    this.appVersion,
    http.Client? client,
    @visibleForTesting PackDownloader? downloader,
    String bundledCatalogJson = bundledVoicePackCatalogJson,
    FreeSpaceCheck? freeSpace,
    bool extractInIsolate = true,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _downloader = downloader ?? BackgroundPackDownloader(),
        _bundledCatalogJson = bundledCatalogJson,
        _freeSpace = freeSpace,
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

  /// Fires after the installed packs changed: a pack was installed,
  /// upgraded or deleted through this repository.
  Stream<void> get changes => _changes.stream;

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
  /// With [wifiOnly], the download waits for Wi-Fi, in the
  /// [VoicePackInstallPhase.waiting] phase, unless [allowMetered].
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
        _notifyChanged();
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
    if (!pack.isSupported) {
      throw VoicePackUnsupportedException(
          '${pack.id} has an unsupported model type or archive format');
    }
    final version = appVersion;
    if (version != null && !pack.isCompatibleWith(version)) {
      throw VoicePackUnsupportedException(
          '${pack.id} needs app version ${pack.minAppVersion}');
    }
    await _start();
    task._throwIfCancelled();
    await _downloadsDir.create(recursive: true);
    final downloads = [
      for (final file in pack.files)
        File(p.join(_downloadsDir.path, file.sha256)),
    ];
    await _checkFreeSpace(pack, downloads);

    final staging = Directory(p.join(_stagingDir.path, pack.id));
    try {
      // Download everything first, so a failure leaves nothing half done.
      final done = List.filled(pack.files.length, 0);
      void report(VoicePackInstallPhase phase) => task._emit(VoicePackProgress(
          phase, done.fold(0, (a, b) => a + b), pack.downloadSize));
      for (var i = 0; i < pack.files.length; i++) {
        task._throwIfCancelled();
        final file = pack.files[i];
        if (!await _isDownloaded(file, downloads[i])) {
          await _download(
              task, file, downloads[i], !allowMetered && wifiOnly, i == 0,
              (bytes, phase) {
            done[i] = bytes;
            report(phase);
          });
        }
        done[i] = file.size;
        task._throwIfCancelled();
        report(i == pack.files.length - 1
            ? VoicePackInstallPhase.verifying
            : VoicePackInstallPhase.downloading);
        await _verify(file, downloads[i]);
      }

      task._throwIfCancelled();
      report(VoicePackInstallPhase.extracting);
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);
      for (var i = 0; i < pack.files.length; i++) {
        task._throwIfCancelled();
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
      task._throwIfCancelled();

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

  /// Picks up downloads left over from an earlier run, once. Nothing is
  /// waiting for them any more, so they are cancelled; a file that finished
  /// downloading meanwhile is kept and checked by the next install.
  Future<void> _start() => _started ??= () async {
        try {
          for (final id in await _downloader.leftoverDownloads()) {
            if (_tasks.values.any((task) => task._downloadId == id)) continue;
            await _downloader.cancel(id);
            await _downloader.forget(id);
          }
        } on Object catch (e) {
          debugPrint('could not clean up leftover voice pack downloads: $e');
        }
      }();

  static Future<bool> _isDownloaded(VoicePackFile file, File download) async =>
      await download.exists() && await download.length() == file.size;

  Future<void> _download(
    VoicePackInstallTask task,
    VoicePackFile file,
    File target,
    bool requiresWiFi,
    bool first,
    void Function(int bytes, VoicePackInstallPhase phase) onProgress,
  ) async {
    final id = file.sha256;
    task._downloadId = id;
    // Between files the download is queued only briefly; only a long wait,
    // e.g. for Wi-Fi, is reported as one, through onState.
    var phase = first
        ? VoicePackInstallPhase.waiting
        : VoicePackInstallPhase.downloading;
    var bytes = 0;
    onProgress(bytes, phase);
    final cancelled = task._cancel.future.then((_) async {
      if (task._downloadId == id) await _downloader.cancel(id);
    });
    Timer? waiting;
    final PackDownloadResult result;
    try {
      result = await _downloader.download(
        PackDownloadRequest(
          id: id,
          url: file.url,
          filePath: target.path,
          requiresWiFi: requiresWiFi,
          displayName: task.pack.name,
        ),
        onProgress: (fraction) {
          bytes = (fraction * file.size).round();
          onProgress(bytes, phase);
        },
        onState: (state) {
          waiting?.cancel();
          void report(VoicePackInstallPhase newPhase) {
            phase = newPhase;
            onProgress(bytes, phase);
          }

          if (state != PackDownloadState.waiting) {
            report(VoicePackInstallPhase.downloading);
          } else if (first && bytes == 0) {
            report(VoicePackInstallPhase.waiting);
          } else {
            waiting = Timer(const Duration(seconds: 1),
                () => report(VoicePackInstallPhase.waiting));
          }
        },
      );
    } finally {
      waiting?.cancel();
      task._downloadId = null;
      cancelled.ignore();
    }
    await _downloader.forget(id);
    switch (result.state) {
      case PackDownloadState.complete:
        return;
      case PackDownloadState.canceled:
        await _deleteQuietly(target);
        throw const VoicePackCancelledException();
      case PackDownloadState.notFound:
        throw VoicePackDownloadException('${file.url} was not found',
            statusCode: result.httpStatusCode ?? 404);
      case PackDownloadState.failed ||
            PackDownloadState.waiting ||
            PackDownloadState.running:
        await _deleteQuietly(target);
        throw VoicePackDownloadException(
            'downloading ${file.url} failed: ${result.message}',
            statusCode: result.httpStatusCode);
    }
  }

  /// Checks [download] against [file]'s SHA-256, deleting it if it differs.
  static Future<void> _verify(VoicePackFile file, File download) async {
    final digest = await crypto.sha256.bind(download.openRead()).first;
    if (digest.toString() != file.sha256) {
      await _deleteQuietly(download);
      throw VoicePackChecksumException(
          '${file.url} has sha256 $digest, expected ${file.sha256}');
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

  Future<void> _checkFreeSpace(VoicePack pack, List<File> downloads) async {
    final freeSpace = _freeSpace;
    if (freeSpace == null) return;
    final available = await freeSpace(directory.path);
    if (available == null) return;
    var required = 0;
    for (var i = 0; i < pack.files.length; i++) {
      final file = pack.files[i];
      final have = await _isDownloaded(file, downloads[i]) ? file.size : 0;
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
      final removed = manifest.remove(id) != null;
      if (removed) await _writeManifest(manifest);
      final dir = packDirectory(id);
      if (await dir.exists()) {
        await _trashDir.create(recursive: true);
        final trashed = await dir.rename(p.join(
            _trashDir.path, '$id-${DateTime.now().microsecondsSinceEpoch}'));
        await _deleteQuietly(trashed);
      }
      if (removed) _notifyChanged();
    });
  }

  void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Deletes leftovers of installs that were interrupted, e.g. by the app
  /// being killed, and cancels downloads nobody is waiting for any more.
  /// Finished downloads are kept for the next install unless [all].
  Future<void> cleanUp({bool all = false}) async {
    await _start();
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
    await _changes.close();
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
