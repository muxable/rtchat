import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Installs a real voice pack through `background_downloader` on a device,
/// then deletes it. It downloads from the internet, so it only runs when
/// asked to:
///
///     flutter test integration_test/voice_pack_download_test.dart \
///       -d emulator-5554 --dart-define=VOICE_PACK_NETWORK_TEST=true
///
/// `--dart-define=VOICE_PACK_ID=...` picks the pack; Supertonic 3 (about
/// 400 MB) by default. `--dart-define=VOICE_PACK_KEEP=true` keeps it installed.
const _run = bool.fromEnvironment('VOICE_PACK_NETWORK_TEST');
const _packId =
    String.fromEnvironment('VOICE_PACK_ID', defaultValue: 'supertonic-3');
const _keep = bool.fromEnvironment('VOICE_PACK_KEEP');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('installs and deletes a real voice pack', (tester) async {
    final support = await getApplicationSupportDirectory();
    final repo = VoicePackRepository(
        directory: Directory('${support.path}/voice_packs'));
    await repo.cleanUp();
    final pack =
        (await repo.availablePacks()).singleWhere((pack) => pack.id == _packId);
    await repo.delete(pack.id);

    final watch = Stopwatch()..start();
    final task = repo.install(pack);
    var phase = '';
    task.progress.listen((progress) {
      if (progress.phase.name != phase) {
        phase = progress.phase.name;
        debugPrint('voice pack: ${watch.elapsed} $progress');
      }
    });
    // runAsync: the download runs on real time, not the test's fake clock.
    final installed = (await tester.runAsync(() => task.done))!;
    debugPrint('voice pack: installed ${installed.id} '
        '(${installed.sizeOnDisk} bytes on disk) in ${watch.elapsed} '
        'at ${installed.directory}');

    for (final value in pack.config.values) {
      for (final path in value is List ? value : [value]) {
        expect(FileSystemEntity.typeSync('${installed.directory}/$path'),
            isNot(FileSystemEntityType.notFound),
            reason: '$path');
      }
    }
    expect(await repo.status(pack), VoicePackStatus.installed);
    if (!_keep) {
      await repo.delete(pack.id);
      expect(Directory(installed.directory).existsSync(), isFalse);
      expect(await repo.status(pack), VoicePackStatus.notInstalled);
    }
    await repo.dispose();
  }, skip: !_run, timeout: const Timeout(Duration(minutes: 30)));
}
