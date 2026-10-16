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

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('voice_packs_test');
    base = Directory(p.join(temp.path, 'voice_packs'));
    downloader = FakePackDownloader();
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  VoicePackRepository repository(
      {List<VoicePack> packs = const [], bool wifiOnly = false}) {
    return VoicePackRepository(
      directory: base,
      packs: packs,
      downloader: downloader,
      wifiOnly: wifiOnly,
    );
  }

  const modelFiles = {'model.onnx': 'weights', 'data/dict': 'dict'};

  /// Serves [pack]'s files with the contents [packFor] made them from.
  void serve(VoicePack pack, Map<String, String> files) {
    for (final file in pack.files) {
      downloader.files[file.url.toString()] =
          Uint8List.fromList(utf8.encode(files[file.path]!));
    }
  }

  /// Serves [pack]'s file at [path] with a byte flipped.
  void corrupt(VoicePack pack, String path) {
    final url = pack.files.firstWhere((file) => file.path == path).url;
    downloader.files[url.toString()]![0] ^= 0xff;
  }

  File installedFile(String id, String name) =>
      File(p.join(base.path, 'packs', id, name));

  File downloadOf(VoicePackFile file) =>
      File(p.join(base.path, 'downloads', file.sha256));

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

  group('install', () {
    test('downloads, verifies and installs a pack', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      final repo = repository(packs: [pack]);
      expect(await repo.availablePacks(), [pack]);
      expect(await repo.status(pack), VoicePackStatus.notInstalled);

      final task = repo.install(pack);
      expect(repo.install(pack), same(task));
      expect(repo.task('a'), same(task));
      expect(await repo.status(pack), VoicePackStatus.installing);
      final progress = task.progress.toList();
      final installed = await task.done;

      expect(installed.id, 'a');
      expect(installed.directory, p.join(base.path, 'packs', 'a'));
      expect(repo.packDirectory('a').path, installed.directory);
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
      expect(await installedFile('a', 'data/dict').readAsString(), 'dict');
      expect(installed.sizeOnDisk, 'weights'.length + 'dict'.length);
      expect(await repo.status(pack), VoicePackStatus.installed);
      expect((await repo.installedPacks()).keys, ['a']);
      expect(repo.task('a'), isNull);

      expect(downloader.requests.map((request) => request.url),
          pack.files.map((file) => file.url));
      expect(downloader.requests.first.filePath,
          downloadOf(pack.files.first).path);
      expect(downloader.forgotten,
          downloader.requests.map((request) => request.id));

      final updates = await progress;
      expect(updates.map((update) => update.phase).toSet().toList(), [
        VoicePackInstallPhase.waiting,
        VoicePackInstallPhase.downloading,
        VoicePackInstallPhase.verifying,
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

    test('rejects a file that would land outside the pack', () async {
      for (final path in ['../evil', '/tmp/evil', 'a/../../evil', '', '.']) {
        final pack = packFor('evil', {path: 'pwned'});
        serve(pack, {path: 'pwned'});
        final repo = repository(packs: [pack]);
        await expectLater(repo.install(pack).done,
            throwsA(isA<VoicePackUnsupportedException>()),
            reason: path);
      }
      expect(downloader.requests, isEmpty);
      expect(temp.listSync(), isEmpty);
    });
  });

  group('downloads', () {
    test('a corrupted download is rejected and deleted', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      corrupt(pack, 'data/dict');
      final repo = repository(packs: [pack]);

      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackChecksumException>()));
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(repo.packDirectory('a').existsSync(), isFalse);
      expect(downloadOf(pack.files.last).existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    });

    test('a failed download fails the install', () async {
      final pack = packFor('a', modelFiles);
      downloader.results[pack.files.first.url.toString()] =
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
      serve(pack, modelFiles);
      await repo.install(pack).done;
      expect(await repo.status(pack), VoicePackStatus.installed);
    });

    test('a missing file fails with its status code', () async {
      final pack = packFor('a', modelFiles);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done,
          throwsA(isA<VoicePackDownloadException>()
              .having((e) => e.statusCode, 'statusCode', 404)));
    });

    test('cancel cancels the download and deletes it', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
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
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
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
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
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
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: true);
      final task = repo.install(pack);
      await task.progress.firstWhere(
          (update) => update.phase == VoicePackInstallPhase.waiting);
      task.cancel();
      await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
    });

    test('mobile data is used when allowed', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: true);
      await repo.install(pack, allowMetered: true).done;
      expect(downloader.requests.map((request) => request.requiresWiFi),
          everyElement(isFalse));
    });

    test('is not required when the repository is not Wi-Fi only', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      downloader.onWiFi = false;
      final repo = repository(packs: [pack], wifiOnly: false);
      await repo.install(pack).done;
      expect(downloader.requests.map((request) => request.requiresWiFi),
          everyElement(isFalse));
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
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      downloader.leftovers = ['old'];
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(downloader.cancelled, ['old']);
    });

    test('a download that finished meanwhile is used', () async {
      final pack = packFor('a', modelFiles);
      serve(pack, modelFiles);
      final first = pack.files.first;
      await downloadOf(first).create(recursive: true);
      await downloadOf(first).writeAsString('weights');
      final repo = repository(packs: [pack]);
      await repo.install(pack).done;
      expect(downloader.requests.map((request) => request.url),
          [pack.files.last.url]);
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
    });

    test('a corrupted one is rejected', () async {
      final pack = packFor('a', modelFiles);
      final first = pack.files.first;
      await downloadOf(first).create(recursive: true);
      await downloadOf(first).writeAsString('WEIGHTS');
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackChecksumException>()));
      expect(downloadOf(first).existsSync(), isFalse);
    });

    test('staging leftovers are deleted', () async {
      final stale = File(p.join(base.path, 'staging', 'a', 'model.onnx'));
      await stale.create(recursive: true);
      await repository().cleanUp();
      expect(leftovers(), isEmpty);
    });
  });

  group('upgrades', () {
    const v2Files = {'model.onnx': 'better weights'};

    test('are detected when the version or a checksum changes', () async {
      final v1 = packFor('a', modelFiles);
      serve(v1, modelFiles);
      final repo = repository(packs: [v1]);
      await repo.install(v1).done;
      final installed = (await repo.installedPack('a'))!;

      final v2 = packFor('a', v2Files, version: 2);
      expect(installed.isOutdatedBy(v2), isTrue);
      expect(await repo.status(v2), VoicePackStatus.upgradeAvailable);

      // Same version, new file.
      final respun = packFor('a', {...modelFiles, 'data/dict': 'new dict'});
      expect(installed.isOutdatedBy(respun), isTrue);
      expect(await repo.status(respun), VoicePackStatus.upgradeAvailable);
      expect(installed.isOutdatedBy(v1), isFalse);
    });

    test('replace the old pack only once the new one is ready', () async {
      final v1 = packFor('a', modelFiles);
      final v2 = packFor('a', v2Files, version: 2);
      serve(v1, modelFiles);
      final repo = repository(packs: [v1]);
      await repo.install(v1).done;

      // A failed upgrade keeps v1.
      serve(v2, v2Files);
      corrupt(v2, 'model.onnx');
      await expectLater(
          repo.install(v2).done, throwsA(isA<VoicePackChecksumException>()));
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
      expect((await repo.installedPack('a'))!.pack.version, 1);

      serve(v2, v2Files);
      await repo.install(v2).done;
      expect(await installedFile('a', 'model.onnx').readAsString(),
          'better weights');
      // Files only in v1 are gone.
      expect(installedFile('a', 'data/dict').existsSync(), isFalse);
      expect((await repo.installedPack('a'))!.pack.version, 2);
      expect(await repo.status(v2), VoicePackStatus.installed);
      expect(leftovers(), isEmpty);
    });
  });

  test('the manifest keeps each installed pack as it was installed', () async {
    final pack = VoicePack(
      id: 'a',
      name: 'Pack A',
      version: 3,
      modelType: VoicePackModelType.supertonic,
      languages: const ['en-US', 'es'],
      speakers: const [
        VoicePackSpeaker(index: 0, name: 'F1', gender: 'female'),
        VoicePackSpeaker(index: 1, name: 'M1', language: 'es'),
      ],
      files: packFor('a', modelFiles).files,
      license: VoicePackLicense(
          name: 'MIT', url: Uri.parse('https://example.com/license')),
      config: const {
        'model': 'model.onnx',
        'dicts': ['data/dict'],
      },
    );
    serve(pack, modelFiles);
    final installed = await repository(packs: [pack]).install(pack).done;

    // A new repository, as after a restart, and a newer pack on offer.
    final newer = packFor('a', const {'model.onnx': 'new'}, version: 4);
    final again = (await repository(packs: [newer]).installedPack('a'))!;
    expect(again.pack.toJson(), pack.toJson());
    expect(again.pack.speakers, pack.speakers);
    expect(again.pack.files, pack.files);
    expect(again.pack.license!.url, pack.license!.url);
    expect(again.sizeOnDisk, installed.sizeOnDisk);
    expect(again.installedAt.isAtSameMomentAs(installed.installedAt), isTrue);
    expect(again.directory, installed.directory);
  });

  test('an unreadable manifest entry is skipped', () async {
    final pack = packFor('a', modelFiles);
    serve(pack, modelFiles);
    final repo = repository(packs: [pack]);
    await repo.install(pack).done;
    final manifest = File(p.join(base.path, 'installed.json'));
    final json = jsonDecode(await manifest.readAsString());
    // E.g. a model type from a newer version of the app.
    json['packs']['a']['pack']['model_type'] = 'from-the-future';
    await manifest.writeAsString(jsonEncode(json));
    expect(await repo.installedPacks(), isEmpty);
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  test('delete removes the pack and its manifest entry', () async {
    final a = packFor('a', modelFiles);
    final b = packFor('b', const {'model.onnx': 'b'});
    serve(a, modelFiles);
    serve(b, const {'model.onnx': 'b'});
    final repo = repository(packs: [a, b]);
    await repo.install(a).done;
    await repo.install(b).done;

    await repo.delete('a');
    expect(repo.packDirectory('a').existsSync(), isFalse);
    expect((await repo.installedPacks()).keys, ['b']);
    final manifest = jsonDecode(
        await File(p.join(base.path, 'installed.json')).readAsString());
    expect((manifest['packs'] as Map).keys, ['b']);
    expect(await repo.status(a), VoicePackStatus.notInstalled);
    expect(leftovers(), isEmpty);

    // Deleting a pack that isn't installed is fine.
    await repo.delete('a');
  });

  test('changes fire after an install and a delete', () async {
    final a = packFor('a', modelFiles);
    serve(a, modelFiles);
    final repo = repository(packs: [a]);
    var changes = 0;
    repo.changes.listen((_) => changes++);

    await repo.install(a).done;
    await repo.delete('a');
    await repo.delete('a'); // nothing left to delete: no change
    await pumpEventQueue();
    expect(changes, 2);
  });

  test('delete cancels an install in progress', () async {
    final pack = packFor('a', modelFiles);
    serve(pack, modelFiles);
    downloader.gate = Completer();
    final repo = repository(packs: [pack]);
    final task = repo.install(pack);
    await task.progress.firstWhere((update) => update.downloadedBytes > 0);
    await repo.delete('a');
    await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  test('a pack whose directory went missing is not installed', () async {
    final pack = packFor('a', modelFiles);
    serve(pack, modelFiles);
    final repo = repository(packs: [pack]);
    await repo.install(pack).done;
    await repo.packDirectory('a').delete(recursive: true);
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  test('offers the bundled packs by default', () async {
    final repo = VoicePackRepository(directory: base, downloader: downloader);
    expect(await repo.availablePacks(), bundledVoicePacks);
    await repo.dispose();
  });
}
