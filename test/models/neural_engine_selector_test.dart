import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/neural_engine_selector.dart';

import '../fakes/fake_tts_engine.dart';
import '../fakes/fake_voice_pack_repository.dart';

void main() {
  late FakeVoicePackRepository repository;
  late TtsModel tts;
  late List<Object> errors;
  late NeuralEngineSelector selector;

  setUp(() {
    repository = FakeVoicePackRepository();
    tts = TtsModel.fromJson({}, engine: FakeTtsEngine());
    errors = [];
    selector = NeuralEngineSelector(
      repository: repository,
      tts: tts,
      reportError: (e, _) => errors.add(e),
      createEngine: (pack) {
        if (pack.id == 'broken') throw const NeuralTtsException('broken');
        return FakeTtsEngine(name: pack.id);
      },
    );
  });

  tearDown(() {
    selector.dispose();
    tts.dispose();
  });

  test('makes a NeuralTtsEngine for the first installed pack by id', () async {
    repository.installed['b'] = installedPack('b');
    repository.installed['a'] = installedPack('a');
    selector = NeuralEngineSelector(
        repository: repository, tts: tts, reportError: (e, _) => fail('$e'));
    await selector.start();
    expect(tts.neuralEngine,
        isA<NeuralTtsEngine>().having((e) => e.pack.id, 'pack', 'a'));
  });

  test('follows installs, upgrades and deletes', () async {
    await selector.start();
    expect(tts.neuralEngine, isNull);

    repository.add(installedPack('a'));
    await pumpEventQueue();
    final first = tts.neuralEngine as FakeTtsEngine;
    expect(first.name, 'a');

    // an unrelated change keeps the engine, and the model it loaded.
    repository.add(installedPack('b'));
    await pumpEventQueue();
    expect(tts.neuralEngine, same(first));

    repository.add(installedPack('a', version: 2));
    await pumpEventQueue();
    expect(tts.neuralEngine, isNot(same(first)));
    expect(first.isDisposed, isTrue);

    repository
      ..remove('a')
      ..remove('b');
    await pumpEventQueue();
    expect(tts.neuralEngine, isNull);
  });

  test('keeps the system voices when the engine cannot be made', () async {
    repository.installed['broken'] = installedPack('broken');
    await selector.start();
    expect(tts.neuralEngine, isNull);
    expect(errors.single, isA<NeuralTtsException>());
  });

  test('stops following changes once disposed', () async {
    await selector.start();
    selector.dispose();
    repository.add(installedPack('a'));
    await pumpEventQueue();
    expect(tts.neuralEngine, isNull);
  });
}
