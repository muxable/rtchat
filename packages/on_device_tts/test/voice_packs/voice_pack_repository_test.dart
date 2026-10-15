import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:on_device_tts/src/voice_packs/pack_downloader.dart';
import 'package:path/path.dart' as p;

import 'fakes.dart';

void main() {
  late Directory temp;
  late Directory base;
  late FakePackDownloader downloader;
  late FakeServer server;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('voice_packs_test');
    base = Directory(p.join(temp.path, 'voice_packs'));
    downloader = FakePackDownloader();
    server = FakeServer();
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  VoicePackRepository repository({
    List<VoicePack> packs = const [],
    int catalogVersion = 1,
    bool wifiOnly = false,
    FreeSpaceCheck? freeSpace,
    Uri? catalogUrl,
    String? appVersion,
    bool extractInIsolate = false,
  }) {
    return VoicePackRepository(
      directory: base,
      client: server.client,
      downloader: downloader,
      bundledCatalogJson: catalogJson(catalogVersion, packs),
      catalogUrl: catalogUrl,
      wifiOnly: wifiOnly,
      appVersion: appVersion,
      freeSpace: freeSpace,
      extractInIsolate: extractInIsolate,
    );
  }

  /// Serves [pack]'s only file as [archive].
  void serve(VoicePack pack, Uint8List archive) {
    downloader.files[pack.files.single.url.toString()] = archive;
  }

  File installedFile(String id, String name) =>
      File(p.join(base.path, 'packs', id, name));

  File downloadOf(VoicePack pack) =>
      File(p.join(base.path, 'downloads', pack.files.single.sha256));

  List<String> leftovers() {
    final dirs = ['staging', 'trash']
        .map((name) => Directory(p.join(base.path, name)))
        .where((dir) => dir.existsSync());
    return [
      for (final dir in dirs)
        ...dir.listSync(recursive: true).map((entity) => entity.path),
    ];
  }

  List<FileSystemEntity> downloads() {
    final dir = Directory(p.join(base.path, 'downloads'));
    return dir.existsSync() ? dir.listSync() : [];
  }

  final modelArchive = tarBz2({
    'model/': '',
    'model/model.onnx': 'weights',
    'model/espeak-ng-data/en_dict': 'dict',
  });

  group('install', () {
    test('downloads, verifies and extracts a pack', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final repo = repository(packs: [pack]);
      expect(await repo.status(pack), VoicePackStatus.notInstalled);

      final task = repo.install(pack);
      expect(repo.install(pack), same(task));
      expect(await repo.status(pack), VoicePackStatus.installing);
      final progress = task.progress.toList();
      final installed = await task.done;

      expect(installed.id, 'a');
      expect(installed.directory, p.join(base.path, 'packs', 'a'));
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
      expect(await installedFile('a', 'espeak-ng-data/en_dict').readAsString(),
          'dict');
      expect(installed.sizeOnDisk, 'weights'.length + 'dict'.length);
      expect(await repo.status(pack), VoicePackStatus.installed);
      expect((await repo.installedPacks()).keys, ['a']);

      final request = downloader.requests.single;
      expect(request.url, pack.files.single.url);
      expect(request.filePath, downloadOf(pack).path);
      expect(downloader.forgotten, [request.id]);

      final updates = await progress;
      expect(updates.map((update) => update.phase).toSet().toList(), [
        VoicePackInstallPhase.waiting,
        VoicePackInstallPhase.downloading,
        VoicePackInstallPhase.verifying,
        VoicePackInstallPhase.extracting,
        VoicePackInstallPhase.done,
      ]);
      expect(updates.last.fraction, 1);
      expect(
          updates.map((update) => update.downloadedBytes),
          orderedEquals(
              [...updates.map((update) => update.downloadedBytes)]..sort()));

      // Nothing is left behind.
      expect(leftovers(), isEmpty);
      expect(downloads(), isEmpty);
    });

    test('extracts in an isolate', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final repo = repository(packs: [pack], extractInIsolate: true);
      await repo.install(pack).done;
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
    });

    test('installs a plain file at its path', () async {
      final bytes = Uint8List.fromList(utf8.encode('tokens'));
      final pack = VoicePack(
        id: 'plain',
        name: 'plain',
        modelTypeName: 'vits',
        languages: const ['en'],
        files: [
          VoicePackFile(
            url: Uri.parse('https://example.com/tokens.txt'),
            size: bytes.length,
            sha256: sha256Of(bytes),
            path: 'data/tokens.txt',
          ),
        ],
      );
      downloader.files['https://example.com/tokens.txt'] = bytes;
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(await installedFile('plain', 'data/tokens.txt').readAsString(),
          'tokens');
    });

    test('rejects a pack this package cannot load', () async {
      final pack = packFor('a', modelArchive, modelType: 'f5-tts');
      final repo = repository(packs: [pack]);
      await expectLater(repo.install(pack).done,
          throwsA(isA<VoicePackUnsupportedException>()));
      expect(downloader.requests, isEmpty);
    });

    test('rejects a pack that needs a newer app', () async {
      final pack = VoicePack.fromJson({
        ...packFor('a', modelArchive).toJson(),
        'min_app_version': '2.0.0',
      });
      final repo = repository(packs: [pack], appVersion: '1.0.0');
      expect(await repo.availablePacks(), isEmpty);
      await expectLater(repo.install(pack).done,
          throwsA(isA<VoicePackUnsupportedException>()));
    });
  });

  group('downloads', () {
    test('a corrupted download is rejected and deleted', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, Uint8List.fromList(modelArchive)..[20] ^= 0xff);
      final repo = repository(packs: [pack]);

      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackChecksumException>()));
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(Directory(p.join(base.path, 'packs', 'a')).existsSync(), isFalse);
      expect(downloads(), isEmpty);
      expect(leftovers(), isEmpty);
    });

    test('a failed download fails the install', () async {
      final pack = packFor('a', modelArchive);
      downloader.results[pack.files.single.url.toString()] =
          const PackDownloadResult(PackDownloadState.failed,
              message: 'connection reset', httpStatusCode: 503);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done,
          throwsA(isA<VoicePackDownloadException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having(
                  (e) => e.message, 'message', contains('connection reset'))));
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(downloads(), isEmpty);

      // It works once the file is there.
      downloader.results.clear();
      serve(pack, modelArchive);
      await repo.install(pack).done;
      expect(await repo.status(pack), VoicePackStatus.installed);
    });

    test('a missing file fails with its status code', () async {
      final pack = packFor('a', modelArchive);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done,
          throwsA(isA<VoicePackDownloadException>()
              .having((e) => e.statusCode, 'statusCode', 404)));
    });

    test('cancel cancels the download and deletes it', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.gate = Completer();
      final repo = repository(packs: [pack]);
      final task = repo.install(pack);
      await task.progress.firstWhere((update) => update.downloadedBytes > 0);

      task.cancel();
      await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
      expect(downloader.cancelled, [downloader.requests.single.id]);
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(downloads(), isEmpty);
      expect(repo.task('a'), isNull);
    });

    test('dispose cancels running installs', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.gate = Completer();
      final repo = repository(packs: [pack]);
      final task = repo.install(pack);
      await task.progress.firstWhere((update) => update.downloadedBytes > 0);
      await repo.dispose();
      await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
      expect(downloader.cancelled, hasLength(1));
    });
  });

  group('Wi-Fi', () {
    test('is required by default', () {
      expect(
          VoicePackRepository(directory: base, downloader: downloader).wifiOnly,
          isTrue);
    });

    test('Wi-Fi-only downloads wait for Wi-Fi', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: true);

      final task = repo.install(pack);
      await task.progress.firstWhere(
          (update) => update.phase == VoicePackInstallPhase.waiting);
      expect(downloader.requests.single.requiresWiFi, isTrue);
      await pumpEventQueue();
      expect(task.latest.phase, VoicePackInstallPhase.waiting);
      expect(await repo.status(pack), VoicePackStatus.installing);

      downloader.onWiFi = true;
      await task.done;
      expect(await repo.status(pack), VoicePackStatus.installed);
    });

    test('a waiting download can be cancelled', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: true);
      final task = repo.install(pack);
      await task.progress.firstWhere(
          (update) => update.phase == VoicePackInstallPhase.waiting);
      task.cancel();
      await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
    });

    test('mobile data is used when allowed', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: true);
      await repo.install(pack, allowMetered: true).done;
      expect(downloader.requests.single.requiresWiFi, isFalse);
    });

    test('is not required when the repository is not Wi-Fi only', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: false);
      await repo.install(pack).done;
      expect(downloader.requests.single.requiresWiFi, isFalse);
    });
  });

  group('leftovers from an earlier run', () {
    test('downloads nobody waits for are cancelled once', () async {
      downloader.leftovers = ['old-1', 'old-2'];
      final repo = repository();
      await repo.cleanUp();
      await repo.cleanUp();
      expect(downloader.leftoverCalls, 1);
      expect(downloader.cancelled, ['old-1', 'old-2']);
      expect(downloader.forgotten, ['old-1', 'old-2']);
    });

    test('are cleaned up before the first install', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      downloader.leftovers = ['old'];
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(downloader.cancelled, ['old']);
    });

    test('a download that finished meanwhile is used', () async {
      final pack = packFor('a', modelArchive);
      await downloadOf(pack).create(recursive: true);
      await downloadOf(pack).writeAsBytes(modelArchive);
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(downloader.requests, isEmpty);
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
    });

    test('a corrupted one is rejected', () async {
      final pack = packFor('a', modelArchive);
      await downloadOf(pack).create(recursive: true);
      await downloadOf(pack)
          .writeAsBytes(Uint8List.fromList(modelArchive)..[20] ^= 0xff);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackChecksumException>()));
      expect(downloadOf(pack).existsSync(), isFalse);
    });

    test('staging leftovers are deleted', () async {
      final stale = File(p.join(base.path, 'staging', 'a', 'model.onnx'));
      await stale.create(recursive: true);
      await repository().cleanUp();
      expect(leftovers(), isEmpty);
    });
  });

  group('archives', () {
    Future<void> expectRejected(Map<String, Object> entries) async {
      final archive = tarBz2(entries);
      final pack = packFor('evil', archive);
      serve(pack, archive);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackArchiveException>()));
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(
          Directory(p.join(base.path, 'packs', 'evil')).existsSync(), isFalse);
      expect(leftovers(), isEmpty);
      expect(downloads(), isEmpty);
      // Nothing was written next to the voice pack directory.
      expect(temp.listSync().map((entity) => p.basename(entity.path)).toList(),
          ['voice_packs']);
    }

    test('reject entries that climb out of the pack', () async {
      await expectRejected({
        'model/model.onnx': 'weights',
        'model/../../../evil.txt': 'pwned',
      });
    });

    test('reject absolute entries', () async {
      await expectRejected({
        'model/model.onnx': 'weights',
        '/tmp/evil.txt': 'pwned',
      });
    });

    test('reject links that point outside the pack', () async {
      await expectRejected({
        'model/model.onnx': 'weights',
        'model/escape': const SymlinkTo('../../..'),
      });
      await expectRejected({
        'model/etc': const SymlinkTo('/etc'),
      });
    });

    test('reject links that only escape through other links', () async {
      // `here/..` looks like the pack's root, but `here` is the root itself,
      // so it is the root's parent.
      await expectRejected({
        'model/model.onnx': 'weights',
        'model/here': const SymlinkTo('.'),
        'model/escape': const SymlinkTo('here/..'),
      });
    });

    test('allow links inside the pack', () async {
      final archive = tarBz2({
        'model/model.onnx': 'weights',
        'model/latest.onnx': const SymlinkTo('model.onnx'),
      });
      final pack = packFor('a', archive);
      serve(pack, archive);
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(await installedFile('a', 'latest.onnx').readAsString(), 'weights');
    });

    test('reject a damaged archive that matches its checksum', () async {
      final damaged = Uint8List.fromList(utf8.encode('not a bzip2 archive'));
      final pack = packFor('a', damaged);
      serve(pack, damaged);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackArchiveException>()));
      expect(downloads(), isEmpty);
    });
  });

  group('upgrades', () {
    final v2Archive = tarBz2({'model/model.onnx': 'better weights'});

    test('are detected when the version or a checksum changes', () async {
      final v1 = packFor('a', modelArchive);
      serve(v1, modelArchive);
      final repo = repository(packs: [v1]);
      await repo.install(v1).done;
      final installed = (await repo.installedPack('a'))!;

      expect(await repo.upgrades(), isEmpty);
      final v2 = packFor('a', v2Archive, version: 2);
      expect(installed.isOutdatedBy(v2), isTrue);
      expect(await repo.status(v2), VoicePackStatus.upgradeAvailable);
      expect(
          await repo.upgrades(
              catalog: VoicePackCatalog(version: 2, allPacks: [v2])),
          [v2]);

      // Same version, new file.
      final respun = VoicePack.fromJson({
        ...v1.toJson(),
        'files': [v2.files.single.toJson()],
      });
      expect(installed.isOutdatedBy(respun), isTrue);
      expect(installed.isOutdatedBy(v1), isFalse);
    });

    test('replace the old pack only once the new one is ready', () async {
      final v1 = packFor('a', modelArchive);
      final v2 = packFor('a', v2Archive, version: 2);
      serve(v1, modelArchive);
      final repo = repository(packs: [v1]);
      await repo.install(v1).done;

      // A failed upgrade keeps v1.
      serve(v2, Uint8List.fromList(v2Archive)..[30] ^= 1);
      await expectLater(
          repo.install(v2).done, throwsA(isA<VoicePackChecksumException>()));
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
      expect((await repo.installedPack('a'))!.pack.version, 1);

      serve(v2, v2Archive);
      await repo.install(v2).done;
      expect(await installedFile('a', 'model.onnx').readAsString(),
          'better weights');
      // Files only in v1 are gone.
      expect(
          installedFile('a', 'espeak-ng-data/en_dict').existsSync(), isFalse);
      expect((await repo.installedPack('a'))!.pack.version, 2);
      expect(await repo.status(v2), VoicePackStatus.installed);
      expect(leftovers(), isEmpty);
    });
  });

  test('delete removes the pack and its manifest entry', () async {
    final a = packFor('a', modelArchive);
    final bArchive = tarBz2({'model/model.onnx': 'b'});
    final b = packFor('b', bArchive);
    serve(a, modelArchive);
    serve(b, bArchive);
    final repo = repository(packs: [a, b]);
    await repo.install(a).done;
    await repo.install(b).done;

    await repo.delete('a');
    expect(Directory(p.join(base.path, 'packs', 'a')).existsSync(), isFalse);
    expect((await repo.installedPacks()).keys, ['b']);
    final manifest = jsonDecode(
        await File(p.join(base.path, 'installed.json')).readAsString());
    expect((manifest['packs'] as Map).keys, ['b']);
    expect(await repo.status(a), VoicePackStatus.notInstalled);
    expect(leftovers(), isEmpty);

    // Deleting a pack that isn't installed is fine.
    await repo.delete('a');
  });

  test('delete cancels an install in progress', () async {
    final pack = packFor('a', modelArchive);
    serve(pack, modelArchive);
    downloader.gate = Completer();
    final repo = repository(packs: [pack]);
    final task = repo.install(pack);
    await task.progress.firstWhere((update) => update.downloadedBytes > 0);
    await repo.delete('a');
    await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  test('a pack whose directory went missing is not installed', () async {
    final pack = packFor('a', modelArchive);
    serve(pack, modelArchive);
    final repo = repository(packs: [pack]);
    await repo.install(pack).done;
    await Directory(p.join(base.path, 'packs', 'a')).delete(recursive: true);
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  test('checks free space before downloading', () async {
    final pack = packFor('a', modelArchive);
    serve(pack, modelArchive);
    final repo = repository(packs: [pack], freeSpace: (_) async => 10);
    await expectLater(repo.install(pack).done,
        throwsA(isA<VoicePackInsufficientSpaceException>()));
    expect(downloader.requests, isEmpty);

    final roomy = repository(packs: [pack], freeSpace: (_) async => 1 << 30);
    await roomy.install(pack).done;
  });

  group('catalog', () {
    final remoteUrl = Uri.parse('https://example.com/catalog.json');
    final pack = packFor('a', modelArchive);
    final newer = packFor('b', modelArchive);

    test('uses the bundled catalog without a URL', () async {
      final repo = repository(packs: [pack]);
      expect((await repo.catalog()).packs.single.id, 'a');
    });

    test('uses a newer remote catalog and keeps it for later', () async {
      server.files[remoteUrl.toString()] =
          utf8.encode(catalogJson(2, [pack, newer]));
      final repo = repository(packs: [pack], catalogUrl: remoteUrl);
      expect((await repo.availablePacks()).map((pack) => pack.id), ['a', 'b']);

      // Offline later: the saved catalog still wins over the bundled one.
      server.files.clear();
      final offline = repository(packs: [pack], catalogUrl: remoteUrl);
      expect((await offline.catalog()).version, 2);
    });

    test('falls back to the bundled catalog', () async {
      // Unreachable.
      final repo = repository(packs: [pack], catalogUrl: remoteUrl);
      expect((await repo.catalog()).version, 1);

      // Not a catalog.
      server.files[remoteUrl.toString()] = utf8.encode('<html>');
      expect((await repo.catalog(refresh: true)).version, 1);

      // A schema this package can't read.
      server.files[remoteUrl.toString()] =
          utf8.encode(jsonEncode({'schema': 99, 'version': 5, 'packs': []}));
      expect((await repo.catalog(refresh: true)).version, 1);

      // Older than the bundled one.
      server.files[remoteUrl.toString()] = utf8.encode(catalogJson(0, []));
      expect((await repo.catalog(refresh: true)).packs.single.id, 'a');
    });

    test('the default bundled catalog has the seed packs', () async {
      final repo = VoicePackRepository(directory: base, downloader: downloader);
      expect((await repo.catalog()).packs, hasLength(1));
      await repo.dispose();
    });
  });
}
