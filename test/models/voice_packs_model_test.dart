import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/models/tts/voice_samples.dart';

import '../fakes/fake_tts_engine.dart';
import '../fakes/fake_voice_pack_repository.dart';

void main() {
  late FakeVoicePackRepository repository;
  late VoicePacksModel model;

  setUp(() {
    repository = FakeVoicePackRepository(packs: [
      testPack(),
      testPack(id: 'thai', name: 'Thai', languages: ['th-TH']),
    ]);
    model = VoicePacksModel(repository, isSupported: true);
  });

  tearDown(() async {
    model.dispose();
    await repository.dispose();
  });

  test('reads the catalog and the installed packs', () async {
    repository.add(testPack(), sizeOnDisk: 5);
    await model.load();
    expect(model.isLoaded, isTrue);
    expect(model.packs.map((p) => p.id), ['supertonic-3', 'thai']);
    expect(model.installed.keys, ['supertonic-3']);
    expect(model.status('supertonic-3'), VoicePackStatus.installed);
    expect(model.status('thai'), VoicePackStatus.notInstalled);
    expect(model.storageUsed, 5);
  });

  test('matches languages by tag', () async {
    repository.add(testPack(languages: ['en', 'pt']));
    await model.load();
    expect(model.isInstalledFor('pt-BR'), isTrue);
    expect(model.isInstalledFor('EN'), isTrue);
    expect(model.isInstalledFor('th'), isFalse);
    expect(model.packFor('th')!.id, 'thai');
    expect(model.packFor('fr')!.id, 'supertonic-3');
    expect(model.packFor('xx'), isNull);
    expect(model.installedLanguages, ['en', 'pt']);
  });

  test('follows packs installed and deleted elsewhere', () async {
    await model.load();
    var notified = 0;
    model.addListener(() => notified++);
    repository.add(testPack());
    await pumpEventQueue();
    expect(model.hasInstalledPack, isTrue);
    await repository.delete('supertonic-3');
    await pumpEventQueue();
    expect(model.hasInstalledPack, isFalse);
    expect(notified, greaterThanOrEqualTo(2));
  });

  test('installs, and remembers why an install failed', () async {
    await model.load();
    final pack = model.packs.first;
    model.install(pack);
    expect(model.isInstalling, isTrue);
    expect(model.status(pack.id), VoicePackStatus.installing);
    expect(model.waitsForWifi(pack.id), isTrue);

    repository.tasks[pack.id]!.fail(const VoicePackDownloadException('x'));
    await pumpEventQueue();
    expect(model.isInstalling, isFalse);
    expect(model.error(pack.id), isA<VoicePackDownloadException>());

    // trying again forgets the error; cancelling isn't one.
    model.install(pack);
    expect(model.error(pack.id), isNull);
    model.cancel(pack.id);
    await pumpEventQueue();
    expect(model.error(pack.id), isNull);
    expect(model.status(pack.id), VoicePackStatus.notInstalled);
  });

  test('is empty where voice packs are not supported', () async {
    final unsupported = VoicePacksModel(repository, isSupported: false);
    addTearDown(unsupported.dispose);
    await unsupported.load();
    expect(unsupported.isLoaded, isTrue);
    expect(unsupported.packs, isEmpty);
    expect(VoicePacksModel(null).isSupported, isFalse);
  });

  group('TtsModel', () {
    late TtsModel tts;
    late FakeTtsEngine neural;

    setUp(() {
      tts = TtsModel.fromJson(const {},
          engine: FakeTtsEngine(), reportError: (e, st) => throw e);
      neural = FakeTtsEngine(availableVoices: packVoices(['en', 'pt']));
    });

    tearDown(() => tts.dispose());

    test('notifies when the neural engines change', () {
      var notified = 0;
      tts.addListener(() => notified++);
      tts.neuralEngines = [neural];
      expect(notified, 1);
      tts.neuralEngines = [neural];
      expect(notified, 1);
    });

    test('lists the languages of the neural voices', () async {
      expect(await tts.neuralLanguages(), isEmpty);
      tts.neuralEngines = [neural];
      expect(await tts.neuralLanguages(), ['en', 'pt']);
    });

    test('previews a voice after what is being read', () async {
      tts.neuralEngines = [neural];
      neural.holdSpeech = true;
      final first = tts.previewVoice('pt-BR', 'M1', 'Olá!');
      final second = tts.previewVoice('en', 'F2', 'Hello!');
      await pumpEventQueue();
      expect(neural.spoken, ['Olá!']);
      expect(neural.utterances.single.voice?.id, 'M1');
      expect(neural.utterances.single.language, 'pt');
      neural.finishSpeaking();
      await first;
      await pumpEventQueue();
      expect(neural.spoken, ['Olá!', 'Hello!']);
      neural.finishSpeaking();
      await second;
    });

    test("doesn't preview a language without a neural voice", () async {
      tts.neuralEngines = [neural];
      await tts.previewVoice('th', 'F1', 'สวัสดี');
      expect(neural.spoken, isEmpty);
    });
  });

  test('voice samples are in the voice language', () {
    expect(voiceSample('pt-BR', fallback: 'x'), contains('voz'));
    expect(voiceSample('de', fallback: 'x'), 'Hallo! So klingt meine Stimme.');
    expect(voiceSample('xx', fallback: 'fallback'), 'fallback');
    for (final language in supertonicLanguages) {
      expect(voiceSample(language, fallback: ''), isNotEmpty, reason: language);
    }
  });
}
