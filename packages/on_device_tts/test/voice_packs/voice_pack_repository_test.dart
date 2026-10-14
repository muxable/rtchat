import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path/path.dart' as p;

import 'fakes.dart';

void main() {
  late Directory temp;
  late Directory base;
  late FakeServer server;
  late List<Duration> sleeps;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('voice_packs_test');
    base = Directory(p.join(temp.path, 'voice_packs'));
    server = FakeServer();
    sleeps = [];
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  VoicePackRepository repository({
    List<VoicePack> packs = const [],
    int catalogVersion = 1,
    bool wifiOnly = false,
    UnmeteredNetworkCheck? isUnmeteredNetwork,
    FreeSpaceCheck? freeSpace,
    Uri? catalogUrl,
    bool extractInIsolate = false,
  }) {
    return VoicePackRepository(
      directory: base,
      client: server.client,
      bundledCatalogJson: catalogJson(catalogVersion, packs),
      catalogUrl: catalogUrl,
      wifiOnly: wifiOnly,
      isUnmeteredNetwork: isUnmeteredNetwork,
      freeSpace: freeSpace,
      retryPolicy: const RetryPolicy(maxAttempts: 3),
      sleep: (delay) async => sleeps.add(delay),
      extractInIsolate: extractInIsolate,
    );
  }

  /// Serves [pack]'s only file as [archive].
  void serve(VoicePack pack, Uint8List archive) {
    server.files[pack.files.single.url.toString()] = archive;
  }

  File installedFile(String id, String name) =>
      File(p.join(base.path, 'packs', id, name));

  List<String> leftovers() {
    final dirs = ['staging', 'trash']
        .map((name) => Directory(p.join(base.path, name)))
        .where((dir) => dir.existsSync());
    return [
      for (final dir in dirs)
        ...dir.listSync(recursive: true).map((entity) => entity.path),
    ];
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

      final updates = await progress;
      expect(updates.last.phase, VoicePackInstallPhase.done);
      expect(updates.last.fraction, 1);
      expect(updates.map((update) => update.downloadedBytes),
          orderedEquals([...updates.map((u) => u.downloadedBytes)]..sort()));
      expect(updates.any((u) => u.phase == VoicePackInstallPhase.extracting),
          isTrue);

      // Nothing is left behind.
      expect(leftovers(), isEmpty);
      expect(Directory(p.join(base.path, 'downloads')).listSync(), isEmpty);
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
      server.files['https://example.com/tokens.txt'] = bytes;
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
      expect(server.client.requests, isEmpty);
    });

    test('rejects a pack that needs a newer app', () async {
      final pack = VoicePack.fromJson({
        ...packFor('a', modelArchive).toJson(),
        'min_app_version': '2.0.0',
      });
      final repo = VoicePackRepository(
        directory: base,
        client: server.client,
        bundledCatalogJson: catalogJson(1, [pack]),
        wifiOnly: false,
        appVersion: '1.0.0',
      );
      expect(await repo.availablePacks(), isEmpty);
      await expectLater(repo.install(pack).done,
          throwsA(isA<VoicePackUnsupportedException>()));
    });
  });

  group('checksums', () {
    test('a corrupted download is rejected and deleted', () async {
      final pack = packFor('a', modelArchive);
      final corrupted = Uint8List.fromList(modelArchive)..[20] ^= 0xff;
      serve(pack, corrupted);
      final repo = repository(packs: [pack]);

      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackChecksumException>()));
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
      expect(Directory(p.join(base.path, 'packs', 'a')).existsSync(), isFalse);
      expect(Directory(p.join(base.path, 'downloads')).listSync(), isEmpty);
      expect(leftovers(), isEmpty);
    });

    test('a download larger than the catalog says is rejected', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, Uint8List.fromList([...modelArchive, 0, 0]));
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackDownloadException>()));
      expect(Directory(p.join(base.path, 'downloads')).listSync(), isEmpty);
    });
  });

  group('interrupted downloads', () {
    test('resume where they stopped after a backoff', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      server.failAfter[pack.files.single.url.toString()] = 50;
      final repo = repository(packs: [pack]);

      await repo.install(pack).done;

      expect(server.client.requests, hasLength(2));
      expect(server.client.requests[0].headers['range'], isNull);
      expect(server.client.requests[1].headers['range'], 'bytes=50-');
      expect(sleeps, [const Duration(seconds: 1)]);
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
    });

    test('start over when the server ignores the range', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      server.failAfter[pack.files.single.url.toString()] = 50;
      server.honourRange = false;
      final repo = repository(packs: [pack]);

      await repo.install(pack).done;
      expect(server.client.requests[1].headers['range'], 'bytes=50-');
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
    });

    test('retry server errors with growing delays, then give up', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      server.statusOverride[pack.files.single.url.toString()] = 503;
      final repo = repository(packs: [pack]);

      await expectLater(
          repo.install(pack).done, throwsA(isA<VoicePackDownloadException>()));
      expect(server.client.requests, hasLength(3));
      expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('do not retry a missing file', () async {
      final pack = packFor('a', modelArchive);
      final repo = repository(packs: [pack]);
      await expectLater(
          repo.install(pack).done,
          throwsA(isA<VoicePackDownloadException>()
              .having((e) => e.statusCode, 'statusCode', 404)));
      expect(server.client.requests, hasLength(1));
    });

    test('resume in a later install after giving up', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final url = pack.files.single.url.toString();
      server.failAfter[url] = 40;
      // Only the first request gets any data; the retry finds no network.
      var calls = 0;
      final flaky = VoicePackRepository(
        directory: base,
        client: FakeClient((request) {
          calls++;
          return calls == 1
              ? server.client.send(request)
              : Future.error(const SocketException('offline'));
        }),
        bundledCatalogJson: catalogJson(1, [pack]),
        wifiOnly: false,
        retryPolicy: const RetryPolicy(maxAttempts: 2),
        sleep: (_) async {},
        extractInIsolate: false,
      );
      await expectLater(
          flaky.install(pack).done, throwsA(isA<VoicePackDownloadException>()));
      expect(await flaky.status(pack), VoicePackStatus.notInstalled);
      final part = File(
          p.join(base.path, 'downloads', '${pack.files.single.sha256}.part'));
      expect(await part.length(), 40);

      server.client.requests.clear();
      await repository(packs: [pack]).install(pack).done;
      expect(server.client.requests.single.headers['range'], 'bytes=40-');
      expect(await installedFile('a', 'model.onnx').readAsString(), 'weights');
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
      expect(Directory(p.join(base.path, 'downloads')).listSync(), isEmpty);
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

  test('a pack whose directory went missing is not installed', () async {
    final pack = packFor('a', modelArchive);
    serve(pack, modelArchive);
    final repo = repository(packs: [pack]);
    await repo.install(pack).done;
    await Directory(p.join(base.path, 'packs', 'a')).delete(recursive: true);
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
  });

  group('network policy', () {
    test('blocks Wi-Fi-only downloads without a network check', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final repo = repository(packs: [pack], wifiOnly: true);
      await expectLater(repo.install(pack).done,
          throwsA(isA<VoicePackDownloadBlockedException>()));
      expect(server.client.requests, isEmpty);
    });

    test('blocks Wi-Fi-only downloads on a metered network', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final repo = repository(
          packs: [pack], wifiOnly: true, isUnmeteredNetwork: () async => false);
      await expectLater(repo.install(pack).done,
          throwsA(isA<VoicePackDownloadBlockedException>()));
      expect(server.client.requests, isEmpty);

      await repo.install(pack, allowMetered: true).done;
      expect(await repo.status(pack), VoicePackStatus.installed);
    });

    test('allows Wi-Fi-only downloads on Wi-Fi', () async {
      final pack = packFor('a', modelArchive);
      serve(pack, modelArchive);
      final repo = repository(
          packs: [pack], wifiOnly: true, isUnmeteredNetwork: () async => true);
      await repo.install(pack).done;
    });

    test('is Wi-Fi-only by default', () {
      expect(VoicePackRepository(directory: base).wifiOnly, isTrue);
    });
  });

  test('checks free space before downloading', () async {
    final pack = packFor('a', modelArchive);
    serve(pack, modelArchive);
    final repo = repository(packs: [pack], freeSpace: (_) async => 10);
    await expectLater(repo.install(pack).done,
        throwsA(isA<VoicePackInsufficientSpaceException>()));
    expect(server.client.requests, isEmpty);

    final roomy = repository(packs: [pack], freeSpace: (_) async => 1 << 30);
    await roomy.install(pack).done;
  });

  test('cancel stops the download and deletes it', () async {
    final pack = packFor('a', modelArchive);
    final gate = Completer<void>();
    final controller = StreamController<List<int>>();
    final client = FakeClient((request) async {
      controller.add(modelArchive.sublist(0, 30));
      gate.complete();
      return http.StreamedResponse(controller.stream, 200,
          contentLength: modelArchive.length);
    });
    final repo = VoicePackRepository(
      directory: base,
      client: client,
      bundledCatalogJson: catalogJson(1, [pack]),
      wifiOnly: false,
      extractInIsolate: false,
    );
    final task = repo.install(pack);
    await gate.future;
    await task.progress.firstWhere((update) => update.downloadedBytes == 30);
    task.cancel();
    await expectLater(task.done, throwsA(isA<VoicePackCancelledException>()));
    expect(await repo.status(pack), VoicePackStatus.notInstalled);
    expect(Directory(p.join(base.path, 'downloads')).listSync(), isEmpty);
    expect(repo.task('a'), isNull);
    await controller.close();
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
      final repo = VoicePackRepository(directory: base);
      expect((await repo.catalog()).packs, hasLength(7));
      await repo.dispose();
    });
  });
}
