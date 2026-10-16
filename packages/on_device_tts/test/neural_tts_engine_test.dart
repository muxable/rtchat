import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

const _methods = MethodChannel('test/onnx');
const _events = EventChannel('test/onnx/events');

/// The native side of `on_device_tts/onnx` on mock channels: `speak` plays
/// until [finish] or `stop`.
class FakeNative {
  final calls = <MethodCall>[];
  final _speaking = <String, Completer<void>>{};
  MockStreamHandlerEventSink? _sink;
  var _handles = 0;

  /// Answers `load`; throw to fail it.
  late Future<String> Function() onLoad = () async => 'h${++_handles}';

  FakeNative() {
    _messenger
      ..setMockMethodCallHandler(_methods, _handle)
      ..setMockStreamHandler(
          _events,
          MockStreamHandler.inline(
              onListen: (_, sink) => _sink = sink,
              onCancel: (_) => _sink = null));
  }

  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void dispose() => _messenger
    ..setMockMethodCallHandler(_methods, null)
    ..setMockStreamHandler(_events, null);

  List<String> get methods => calls.map((call) => call.method).toList();

  List<Map<Object?, Object?>> argsOf(String method) => [
        for (final call in calls)
          if (call.method == method) call.arguments as Map<Object?, Object?>,
      ];

  void emit(String id, String type) =>
      _sink?.success({'utteranceId': id, 'type': type, 'elapsedMs': 100});

  /// Ends every utterance playing with [type].
  void finish([String type = 'done']) {
    for (final MapEntry(key: id, value: done) in _speaking.entries) {
      emit(id, type);
      done.complete();
    }
    _speaking.clear();
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'load':
        return onLoad();
      case 'speak':
        final id = (call.arguments as Map)['utteranceId'] as String;
        final done = _speaking[id] = Completer<void>();
        emit(id, 'firstAudio');
        await done.future;
      case 'stop':
        finish('stopped');
    }
    return null;
  }
}

InstalledVoicePack supertonicPack({List<VoicePackSpeaker>? speakers}) =>
    InstalledVoicePack(
      pack: VoicePack(
        id: 'supertonic-3',
        name: 'Supertonic 3',
        modelType: VoicePackModelType.supertonic,
        languages: const ['en', 'ko', 'es'],
        speakers: speakers ??
            const [
              VoicePackSpeaker(index: 0, name: 'F1'),
              VoicePackSpeaker(index: 1, name: 'Marco'),
            ],
        files: [
          VoicePackFile(
              url: Uri.parse('https://example.com/vocoder.onnx'),
              size: 1,
              sha256: 'a' * 64,
              path: 'onnx/vocoder.onnx'),
        ],
        config: const {
          'voice_styles': ['voice_styles/F1.json', 'voice_styles/M1.json'],
        },
      ),
      directory: '/packs/supertonic-3',
      sizeOnDisk: 1,
      installedAt: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late NeuralTtsEngine engine;

  NeuralTtsEngine create({int steps = 5}) => NeuralTtsEngine(supertonicPack(),
      steps: steps,
      platform: OnnxTtsPlatform(methods: _methods, events: _events));

  setUp(() {
    native = FakeNative();
    engine = create();
  });

  tearDown(() {
    native.finish();
    native.dispose();
  });

  /// Speaks [text] and lets the fake finish playing it.
  Future<void> speakNow(String text,
      {TtsVoice? voice, double rate = 0.5, String? language}) async {
    final speaking =
        engine.speak(text, voice: voice, rate: rate, language: language);
    await pumpEventQueue();
    native.finish();
    await speaking;
  }

  test('loads lazily, once, and keeps the model warm', () async {
    engine = create(steps: 8);
    expect(engine.isLoaded, isFalse);
    await engine.voices();
    expect(native.calls, isEmpty, reason: 'voices come from the pack');

    await speakNow('Hello chat, how is everyone doing?');
    await speakNow('Second message here');
    expect(native.methods, ['load', 'speak', 'speak']);
    expect(native.argsOf('load').single, {
      'modelType': 'supertonic',
      'modelDir': '/packs/supertonic-3',
      'numThreads': 2,
      'provider': 'cpu',
    });
    expect(native.argsOf('speak').map((a) => a['steps']), [8, 8]);
  });

  test('a failed load is retried on the next speak', () async {
    native.onLoad = () async =>
        throw PlatformException(code: 'load_failed', message: 'OOM');
    await expectLater(
        engine.speak('Hello there everyone'),
        throwsA(isA<NeuralTtsLoadException>()
            .having((e) => e.cause.message, 'cause', 'OOM')));
    expect(engine.isLoaded, isFalse);
    // other errors aren't load failures.
    native.onLoad = () async => throw PlatformException(code: 'bad_args');
    await expectLater(engine.load(), throwsA(isA<PlatformException>()));

    native.onLoad = () async => 'h9';
    await speakNow('Hello there everyone');
    expect(native.argsOf('speak').single['handle'], 'h9');
  });

  test('speaks the whole message with the language, voice and speed',
      () async {
    await speakNow('Muxfd said: that was the cleanest clutch, GG everyone!',
        rate: 0.8);
    await speakNow('Hola a todos',
        voice: const TtsVoice(id: 'M1', name: 'Marco', locale: 'es'));
    final [first, second] = native.argsOf('speak');
    expect(first['segments'],
        ['Muxfd said: that was the cleanest clutch, GG everyone!']);
    expect(first['language'], 'en');
    expect(first['voiceId'], 'F1', reason: "the pack's first speaker");
    expect(first['speed'], 1.6);
    expect((second['language'], second['voiceId']), ('es', 'M1'));
  });

  test('maps the rate to the native speed', () {
    expect([0.0, 0.4, 0.5, 1.0, 5.0].map(NeuralTtsEngine.speedForRate),
        [0.7, 0.8, 1.0, 2.0, 2.0]);
  });

  test('speaks nothing for blank text', () async {
    await engine.speak('   ');
    expect(native.calls, isEmpty);
  });

  test('stop cuts off its own utterance, also one waiting to load', () async {
    final speaking = engine.speak('A long message to stop');
    await pumpEventQueue();
    await engine.stop();
    await speaking;
    expect(native.methods, ['load', 'speak', 'stop']);

    // An idle engine leaves other engines' speech alone.
    await engine.stop();
    expect(native.methods, hasLength(3));

    await engine.release();
    final loaded = Completer<String>();
    native.onLoad = () => loaded.future;
    final waiting = engine.speak('Hello there chat');
    await pumpEventQueue();
    await engine.stop();
    loaded.complete('h2');
    await waiting;
    expect(native.methods.where((m) => m == 'speak'), hasLength(1));
  });

  test("events carry only this engine's utterances", () async {
    final events = <OnnxTtsEventType>[];
    final sub = engine.events.listen((event) => events.add(event.type));
    await pumpEventQueue();
    await speakNow('Hello there chat');
    native.emit('someone-else', 'firstAudio');
    await pumpEventQueue();
    await sub.cancel();
    expect(events, [OnnxTtsEventType.firstAudio, OnnxTtsEventType.done]);
  });

  test("lists each speaker in each of the pack's languages", () async {
    expect(await engine.voices(), hasLength(6));
    expect(await engine.voices(language: 'ko'), const [
      TtsVoice(id: 'F1', name: 'F1', locale: 'ko'),
      TtsVoice(id: 'M1', name: 'Marco', locale: 'ko'),
    ]);
    engine = NeuralTtsEngine(supertonicPack(speakers: const [
      VoicePackSpeaker(index: 0, name: 'F1', language: 'es'),
    ]));
    expect(await engine.voices(),
        const [TtsVoice(id: 'F1', name: 'F1', locale: 'es')]);
  });

  test('release unloads, and the next speak loads again', () async {
    await engine.release();
    expect(native.calls, isEmpty, reason: 'nothing to release');

    final speaking = engine.speak('Hello there chat');
    await pumpEventQueue();
    await engine.release();
    await speaking;
    expect(native.methods, ['load', 'speak', 'stop', 'unload']);

    await speakNow('Hello again chat');
    expect(native.argsOf('speak').last['handle'], 'h2');
  });

  test('dispose unloads once, and the engine cannot speak after', () async {
    await speakNow('Hello there chat');
    await engine.dispose();
    await engine.dispose();
    expect(native.argsOf('unload'), hasLength(1));
    expect(engine.speak('hi'), throwsStateError);
  });
}
