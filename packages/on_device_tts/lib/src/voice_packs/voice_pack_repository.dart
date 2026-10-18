import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'bundled_catalog.dart';
import 'installed_voice_pack.dart';
import 'pack_downloader.dart';
import 'voice_pack.dart';
import 'voice_pack_exceptions.dart';

/// Where a pack stands on this device.
enum VoicePackStatus { notInstalled, installing, installed, upgradeAvailable }

/// What an install is doing.
enum VoicePackInstallPhase {
  /// Queued: waiting for Wi-Fi, for the system to run it, or to retry.
  waiting,
  downloading,
  verifying,
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
class VoicePackRepository {
  /// The directory everything is stored in.
  final Directory directory;

  /// Whether downloads wait for Wi-Fi unless the caller allows mobile data
  /// for one install.
  final bool wifiOnly;

  final List<VoicePack> _packs;
  final PackDownloader _downloader;

  final _tasks = <String, VoicePackInstallTask>{};
  final _changes = StreamController<void>.broadcast();
  Future<void> _manifestLock = Future.value();
  Future<void>? _started;

  /// Offers [packs], [bundledVoicePacks] by default. Files download in the
  /// background with [BackgroundPackDownloader] unless [downloader] says
  /// otherwise, which is for tests.
  VoicePackRepository({
    required this.directory,
    this.wifiOnly = true,
    List<VoicePack>? packs,
    @visibleForTesting PackDownloader? downloader,
  })  : _packs = packs ?? bundledVoicePacks,
        _downloader = downloader ?? BackgroundPackDownloader();

  Directory get _packsDir => Directory(p.join(directory.path, 'packs'));
  Directory get _downloadsDir => Directory(p.join(directory.path, 'downloads'));
  Directory get _stagingDir => Directory(p.join(directory.path, 'staging'));
  Directory get _trashDir => Directory(p.join(directory.path, 'trash'));
  File get _manifestFile => File(p.join(directory.path, 'installed.json'));

  /// The directory pack [id] is or would be installed in.
  Directory packDirectory(String id) => Directory(p.join(_packsDir.path, id));

  /// The packs that can be installed.
  Future<List<VoicePack>> availablePacks() async => _packs;

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

  /// Fires after a pack was installed, upgraded or deleted through this
  /// repository.
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
        if (!_changes.isClosed) _changes.add(null);
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
    for (final file in pack.files) {
      if (!isSafeRelativePath(file.path)) {
        throw VoicePackUnsupportedException(
            '${pack.id} has a file outside its directory: ${file.path}');
      }
    }
    await _start();
    task._throwIfCancelled();
    await _downloadsDir.create(recursive: true);
    final downloads = [
      for (final file in pack.files)
        File(p.join(_downloadsDir.path, file.sha256)),
    ];

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
      if (await staging.exists()) await staging.delete(recursive: true);
      for (var i = 0; i < pack.files.length; i++) {
        final target = p.join(staging.path, pack.files[i].path);
        await Directory(p.dirname(target)).create(recursive: true);
        await downloads[i].rename(target);
      }
      task._throwIfCancelled();

      final installed = InstalledVoicePack(
        pack: pack,
        directory: packDirectory(pack.id).path,
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
      if (removed && !_changes.isClosed) _changes.add(null);
    });
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

  /// Cancels running installs.
  Future<void> dispose() async {
    final running = _tasks.values.toList();
    for (final task in running) {
      task.cancel();
    }
    for (final task in running) {
      await task.done.then((_) {}, onError: (_) {});
    }
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
