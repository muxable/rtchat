import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/neural_engine_selector.dart';

import '../fakes/fake_tts_engine.dart';

/// A [VoicePackRepository] with packs installed in memory.
class FakeVoicePackRepository implements VoicePackRepository {
  final installed = <String, InstalledVoicePack>{};
  final _changes = StreamController<void>.broadcast();

  void add(InstalledVoicePack pack) {
    installed[pack.id] = pack;
    _changes.add(null);
  }

  void remove(String id) {
    installed.remove(id);
    _changes.add(null);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Map<String, InstalledVoicePack>> installedPacks() async =>
      Map.of(installed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InstalledVoicePack pack(String id,
        {String modelType = 'supertonic', int version = 1}) =>
    InstalledVoicePack(
      pack: VoicePack(
        id: id,
        name: id,
        version: version,
        modelTypeName: modelType,
        languages: const ['en'],
        files: [
          VoicePackFile(
              url: Uri.parse('https://example.com/$id'),
              size: 1,
              sha256: 'a' * 64,
              path: 'onnx/vocoder.onnx'),
        ],
      ),
      directory: '/packs/$id',
      catalogVersion: 1,
      sizeOnDisk: 1,
      installedAt: DateTime(2026),
    );

void main() {
  late FakeVoicePackRepository repository;
  late TtsModel tts;
  late List<String> created;
  late List<FakeTtsEngine> engines;
  late NeuralEngineSelector selector;
  late List<Object> errors;
  DeviceMemory? deviceMemory;

  setUp(() {
    deviceMemory = const DeviceMemory(totalBytes: 8 << 30);
    repository = FakeVoicePackRepository();
    tts = TtsModel.fromJson({},
        engine: FakeTtsEngine(), reportError: (e, _) => errors.add(e));
    created = [];
    engines = [];
    errors = [];
    selector = NeuralEngineSelector(
      repository: repository,
      tts: tts,
      createEngine: (pack) {
        created.add('${pack.id}@${pack.pack.version}');
        final engine = FakeTtsEngine();
        engines.add(engine);
        return engine;
      },
      reportError: (e, _) => errors.add(e),
      deviceMemory: () async => deviceMemory,
    );
  });

  tearDown(() {
    selector.dispose();
    tts.dispose();
  });

  test('keeps the system voices without an installed pack', () async {
    await selector.start();
    expect(tts.neuralEngine, isNull);
    expect(created, isEmpty);
  });

  test('uses a neural engine for an installed pack at startup', () async {
    repository.installed['supertonic-3'] = pack('supertonic-3');
    await selector.start();
    expect(created, ['supertonic-3@1']);
    expect(tts.neuralEngine, same(engines.single));
  });

  test('builds the real NeuralTtsEngine by default', () async {
    repository.installed['supertonic-3'] = pack('supertonic-3');
    final real = NeuralEngineSelector(repository: repository, tts: tts);
    await real.start();
    expect(tts.neuralEngine, isA<NeuralTtsEngine>());
    expect((tts.neuralEngine as NeuralTtsEngine).pack.id, 'supertonic-3');
    real.dispose();
  });

  test('follows installs, upgrades and deletes', () async {
    await selector.start();

    repository.add(pack('supertonic-3'));
    await pumpEventQueue();
    expect(tts.neuralEngine, same(engines.last));

    // An unrelated change keeps the engine, and the model it loaded.
    repository.add(pack('kokoro', modelType: 'kokoro'));
    await pumpEventQueue();
    expect(created, ['supertonic-3@1']);

    repository.add(pack('supertonic-3', version: 2));
    await pumpEventQueue();
    expect(created, ['supertonic-3@1', 'supertonic-3@2']);
    expect(tts.neuralEngine, same(engines.last));
    expect(engines.first.isDisposed, isTrue);

    repository.remove('supertonic-3');
    await pumpEventQueue();
    expect(tts.neuralEngine, isNull);
    expect(engines.last.isDisposed, isTrue);
  });

  test('ignores packs the neural engine cannot speak with', () async {
    repository.installed['kokoro'] = pack('kokoro', modelType: 'kokoro');
    await selector.start();
    expect(tts.neuralEngine, isNull);
  });

  test('orders the usable packs by id', () {
    expect(
        NeuralEngineSelector.choose([
          pack('c'),
          pack('a', modelType: 'kitten'),
          pack('b'),
        ]).map((pack) => pack.id),
        ['b', 'c']);
    expect(NeuralEngineSelector.choose([]), isEmpty);
  });

  test('gives every usable pack an engine, keeping unchanged ones', () async {
    repository.installed['b'] = pack('b');
    await selector.start();
    expect(tts.neuralEngines, [same(engines[0])]);

    repository.add(pack('a'));
    await pumpEventQueue();
    expect(created, ['b@1', 'a@1']);
    // In order of preference, and b's engine (with its model) stays.
    expect(tts.neuralEngines, [same(engines[1]), same(engines[0])]);
    expect(engines[0].isDisposed, isFalse);

    repository.remove('a');
    await pumpEventQueue();
    expect(tts.neuralEngines, [same(engines[0])]);
    expect(engines[1].isDisposed, isTrue);
    expect(engines[0].isDisposed, isFalse);
  });

  test('keeps the system voices when the engine cannot be made', () async {
    repository.installed['supertonic-3'] = pack('supertonic-3');
    final failing = NeuralEngineSelector(
      repository: repository,
      tts: tts,
      createEngine: (_) => throw const NeuralTtsException('bad layout'),
      reportError: (e, _) => errors.add(e),
      deviceMemory: () async => deviceMemory,
    );
    await failing.start();
    expect(tts.neuralEngine, isNull);
    expect(errors.single, isA<NeuralTtsException>());
    failing.dispose();
  });

  group('device memory', () {
    test('a big enough device loads neural voices', () async {
      repository.installed['supertonic-3'] = pack('supertonic-3');
      await selector.start();
      expect(tts.neuralFallback, isNull);
    });

    test('a low-RAM device reads with the system voices', () async {
      deviceMemory =
          const DeviceMemory(totalBytes: 4 << 30, isLowRamDevice: true);
      repository.installed['supertonic-3'] = pack('supertonic-3');
      await selector.start();
      expect(tts.neuralFallback, NeuralTtsFallback.lowMemoryDevice);
      expect(tts.isNeuralFallbackNoticePending, isTrue);
    });

    test('a 2 GB device reads with the system voices', () async {
      deviceMemory = const DeviceMemory(totalBytes: 1900 << 20);
      await selector.start();
      expect(tts.neuralFallback, NeuralTtsFallback.lowMemoryDevice);
    });

    test('is checked once', () async {
      var checks = 0;
      final counting = NeuralEngineSelector(
        repository: repository,
        tts: tts,
        createEngine: (_) => FakeTtsEngine(),
        deviceMemory: () async {
          checks++;
          return deviceMemory;
        },
      );
      await counting.start();
      await counting.start();
      await counting.refresh();
      expect(checks, 1);
      counting.dispose();
    });

    test('an unknown device (e.g. no native engine) is allowed', () async {
      deviceMemory = null;
      await selector.start();
      expect(tts.neuralFallback, isNull);
    });
  });

  test('stops following changes once disposed', () async {
    await selector.start();
    selector.dispose();
    repository.add(pack('supertonic-3'));
    await pumpEventQueue();
    expect(tts.neuralEngine, isNull);
  });
}
