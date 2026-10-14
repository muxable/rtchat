import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

const _methods = MethodChannel('test/onnx');
const _events = EventChannel('test/onnx/events');

/// The native side of `on_device_tts/onnx`, faked on mock channels.
class FakeNative {
  final calls = <MethodCall>[];
  final _speaking = <String, Completer<void>>{};
  MockStreamHandlerEventSink? _sink;

  /// Answers `load`; throw to fail it.
  Future<Object?> Function() onLoad = () async => 'supertonic-1';

  /// What `speak` does: holds speech until [finish], unless set.
  Future<void> Function(MethodCall call)? onSpeak;

  /// The voices `voices` lists.
  List<Map<String, Object?>> voices = [
    {'id': 'F1', 'name': 'F1'},
    {'id': 'M1', 'name': 'M1'},
  ];

  var _handles = 0;

  FakeNative() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methods, _handle);
    messenger.setMockStreamHandler(
        _events,
        MockStreamHandler.inline(
          onListen: (_, sink) => _sink = sink,
          onCancel: (_) => _sink = null,
        ));
  }

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methods, null);
    messenger.setMockStreamHandler(_events, null);
  }

  List<MethodCall> callsTo(String method) =>
      calls.where((call) => call.method == method).toList();

  Map<Object?, Object?> argsOf(String method) =>
      callsTo(method).single.arguments as Map<Object?, Object?>;

  /// Sends an event as the native engine would.
  void emit(String utteranceId, String type, {String? message}) {
    _sink?.success({
      'utteranceId': utteranceId,
      'type': type,
      'elapsedMs': 100,
      if (message != null) 'message': message,
    });
  }

  /// Finishes the utterance playing, sending `done`.
  void finish() {
    for (final MapEntry(key: id, value: done) in _speaking.entries) {
      emit(id, 'done');
      done.complete();
    }
    _speaking.clear();
  }

  bool get isSpeaking => _speaking.isNotEmpty;

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final args = call.arguments as Map<Object?, Object?>?;
    switch (call.method) {
      case 'load':
        final handle = await onLoad();
        return handle ?? 'supertonic-${++_handles}';
      case 'voices':
        return voices;
      case 'speak':
        final id = args!['utteranceId'] as String;
        if (_speaking.isNotEmpty) {
          throw PlatformException(code: 'busy');
        }
        final speak = onSpeak;
        if (speak != null) {
          await speak(call);
          return null;
        }
        final done = Completer<void>();
        _speaking[id] = done;
        emit(id, 'firstAudio');
        await done.future;
        return null;
      case 'stop':
        for (final MapEntry(key: id, value: done) in _speaking.entries) {
          emit(id, 'stopped');
          done.complete();
        }
        _speaking.clear();
        return null;
      case 'unload':
        return null;
    }
    throw MissingPluginException();
  }
}

InstalledVoicePack supertonicPack({
  String id = 'supertonic-3',
  String modelType = 'supertonic',
  List<VoicePackSpeaker>? speakers,
  Map<String, Object?>? config,
}) {
  return InstalledVoicePack(
    pack: VoicePack(
      id: id,
      name: 'Supertonic 3',
      modelTypeName: modelType,
      languages: const ['en', 'ko', 'es'],
      speakers: speakers ??
          const [
            VoicePackSpeaker(index: 0, name: 'F1', gender: 'female'),
            VoicePackSpeaker(index: 1, name: 'M1', gender: 'male'),
          ],
      files: [
        VoicePackFile(
            url: Uri.parse('https://example.com/model.onnx'),
            size: 1,
            sha256: 'a' * 64,
            path: 'onnx/vocoder.onnx'),
      ],
      config: config ??
          const {
            'duration_predictor': 'onnx/duration_predictor.onnx',
            'text_encoder': 'onnx/text_encoder.onnx',
            'vector_estimator': 'onnx/vector_estimator.onnx',
            'vocoder': 'onnx/vocoder.onnx',
            'tts_json': 'onnx/tts.json',
            'unicode_indexer': 'onnx/unicode_indexer.json',
            'voice_styles': ['voice_styles/F1.json', 'voice_styles/M1.json'],
          },
    ),
    directory: '/data/voice_packs/packs/$id',
    catalogVersion: 1,
    sizeOnDisk: 1,
    installedAt: DateTime(2026),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late OnnxTtsPlatform platform;
  late NeuralTtsEngine engine;

  setUp(() {
    native = FakeNative();
    platform = OnnxTtsPlatform(methods: _methods, events: _events);
    engine = NeuralTtsEngine(supertonicPack(), platform: platform);
  });

  tearDown(() async {
    native.finish();
    native.dispose();
  });

  /// Speaks [text] with the fake finishing playback at once.
  Future<void> speakNow(String text,
      {TtsVoice? voice,
      double rate = TtsEngine.normalRate,
      String? language}) async {
    final speaking =
        engine.speak(text, voice: voice, rate: rate, language: language);
    await pumpEventQueue();
    native.finish();
    await speaking;
  }

  group('load', () {
    test('happens on first use, once, with the pack and options', () async {
      engine = NeuralTtsEngine(supertonicPack(),
          platform: platform,
          numThreads: 4,
          provider: OnnxProvider.xnnpack,
          steps: 8);
      expect(engine.isLoaded, isFalse);
      expect(native.calls, isEmpty);

      await speakNow('Hello chat, how is everyone doing?');
      await speakNow('Second message here');
      await engine.voices();

      expect(native.callsTo('load'), hasLength(1));
      expect(native.argsOf('load'), {
        'modelType': 'supertonic',
        'modelDir': '/data/voice_packs/packs/supertonic-3',
        'numThreads': 4,
        'provider': 'xnnpack',
      });
      expect(engine.isLoaded, isTrue);
      expect(native.callsTo('speak').map((c) => (c.arguments as Map)['steps']),
          [8, 8]);
    });

    test('is shared by concurrent first calls', () async {
      final loaded = Completer<Object?>();
      native.onLoad = () => loaded.future;
      final a = engine.load();
      final b = engine.load();
      loaded.complete('supertonic-7');
      await Future.wait([a, b]);
      expect(native.callsTo('load'), hasLength(1));
    });

    test('works out a flat model directory from the config', () async {
      engine = NeuralTtsEngine(
          supertonicPack(config: const {
            'tts_json': 'model/tts.json',
            'vocoder': 'model/vocoder.onnx',
            'voice_styles': ['model/voice_styles/F1.json'],
          }),
          platform: platform);
      expect(
          engine.modelDirectory, '/data/voice_packs/packs/supertonic-3/model');
    });

    test('rejects a layout the native engine cannot load', () {
      expect(
          () => NeuralTtsEngine(
              supertonicPack(config: const {
                'tts_json': 'elsewhere/tts.json',
                'voice_styles': ['voice_styles/F1.json'],
              }),
              platform: platform),
          throwsA(isA<NeuralTtsException>()));
      expect(
          () => NeuralTtsEngine(
              supertonicPack(config: const {
                'voice_styles': ['styles/F1.json'],
              }),
              platform: platform),
          throwsA(isA<NeuralTtsException>()));
    });

    test('rejects model types it cannot speak', () {
      expect(NeuralTtsEngine.canSpeak(supertonicPack().pack), isTrue);
      expect(NeuralTtsEngine.canSpeak(supertonicPack(modelType: 'kokoro').pack),
          isFalse);
      expect(
          () => NeuralTtsEngine(supertonicPack(modelType: 'kokoro'),
              platform: platform),
          throwsA(isA<NeuralTtsException>()));
    });

    test('only load failures become NeuralTtsLoadExceptions', () async {
      native.onLoad = () async => throw PlatformException(code: 'bad_args');
      await expectLater(
          engine.load(),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'bad_args')));
    });

    test('failures propagate and the next call tries again', () async {
      native.onLoad = () async =>
          throw PlatformException(code: 'load_failed', message: 'missing');
      await expectLater(
          engine.speak('Hello there everyone'),
          throwsA(isA<NeuralTtsLoadException>()
              .having((e) => e.cause, 'cause', isA<PlatformException>())
              .having((e) => e.message, 'message', contains('missing'))));
      expect(engine.isLoaded, isFalse);
      expect(native.callsTo('speak'), isEmpty);

      native.onLoad = () async => 'supertonic-2';
      await speakNow('Hello there everyone');
      expect(native.callsTo('load'), hasLength(2));
      expect(native.argsOf('speak')['handle'], 'supertonic-2');
    });
  });

  group('speak', () {
    test('sends the clauses, language, voice and speed', () async {
      await speakNow('Muxfd said: that was the cleanest clutch, GG everyone!');
      final args = native.argsOf('speak');
      expect(args['handle'], 'supertonic-1');
      expect(args['segments'], [
        'Muxfd said:',
        'that was the cleanest clutch,',
        'GG everyone!',
      ]);
      expect(args['language'], 'en');
      expect(args['voiceId'], 'F1', reason: "the pack's first speaker");
      expect(args['speed'], 1.0);
      expect(args['steps'], 5);
      expect(args['utteranceId'], isA<String>());
    });

    test('can leave the text whole', () async {
      engine = NeuralTtsEngine(supertonicPack(),
          platform: platform, splitClauses: false);
      await speakNow('  Hello chat, thanks for the follow!  ');
      expect(native.argsOf('speak')['segments'],
          ['Hello chat, thanks for the follow!']);
    });

    test('completes only once playback is done', () async {
      var done = false;
      final speaking = engine.speak('Hello chat').then((_) => done = true);
      await pumpEventQueue();
      expect(native.isSpeaking, isTrue);
      expect(done, isFalse);
      native.finish();
      await speaking;
      expect(done, isTrue);
    });

    test('speaks nothing for blank text', () async {
      await engine.speak('   ');
      expect(native.calls, isEmpty);
    });

    test('picks the language from the call, the voice, then the default',
        () async {
      engine = NeuralTtsEngine(supertonicPack(),
          platform: platform, defaultLanguage: 'es');
      await speakNow('Hola a todos');
      await speakNow('Hello everyone',
          voice: const TtsVoice(id: 'M1', name: 'M1', locale: 'ko'));
      await speakNow('Hello everyone',
          voice: const TtsVoice(id: 'M1', name: 'M1', locale: 'ko'),
          language: 'en-US');
      final speaks = native.callsTo('speak').map((c) => c.arguments as Map);
      expect(speaks.map((a) => a['language']), ['es', 'ko', 'en-US']);
      expect(speaks.map((a) => a['voiceId']), ['F1', 'M1', 'M1']);
    });

    test('keeps Korean and Japanese clauses to the shorter native limit',
        () async {
      await speakNow('가' * 250, language: 'ko');
      expect(
          native.argsOf('speak')['segments'], ['가' * 120, '가' * 120, '가' * 10]);
      expect(NeuralTtsEngine.maxSegmentLengthFor('ja-JP'), 120);
      expect(NeuralTtsEngine.maxSegmentLengthFor('en'), 300);
    });

    test('maps the rate to the native speed', () async {
      for (final rate in [0.0, 0.25, 0.4, 0.5, 0.8, 1.0]) {
        await speakNow('Hello there chat', rate: rate);
      }
      expect(native.callsTo('speak').map((c) => (c.arguments as Map)['speed']),
          [0.7, 0.7, 0.8, 1.0, 1.6, 2.0]);
      expect(NeuralTtsEngine.speedForRate(5), 2.0);
      expect(NeuralTtsEngine.speedForRate(-1), 0.7);
    });

    test('ignores the pitch', () async {
      final speaking = engine.speak('Hello there chat', pitch: 2.0);
      await pumpEventQueue();
      native.finish();
      await speaking;
      expect(native.argsOf('speak').containsKey('pitch'), isFalse);
    });

    test('falls back to the native voices when the pack lists no speakers',
        () async {
      engine = NeuralTtsEngine(supertonicPack(speakers: const []),
          platform: platform);
      native.voices = [
        {'id': 'M3', 'name': 'M3'},
      ];
      await speakNow('Hello there chat');
      expect(native.argsOf('speak')['voiceId'], 'M3');
    });

    test('propagates native errors', () async {
      native.onSpeak = (call) async => throw PlatformException(
          code: 'speak_failed', message: 'AudioTrack died');
      await expectLater(
          engine.speak('Hello there chat'),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'speak_failed')));
      // The engine is still usable.
      native.onSpeak = null;
      await speakNow('Hello again chat');
    });

    test('throws once disposed', () async {
      await engine.dispose();
      expect(() => engine.speak('hi'), throwsStateError);
    });
  });

  group('stop', () {
    test('stops the native utterance and completes speak', () async {
      final speaking = engine.speak('A long message, with clauses, to stop');
      await pumpEventQueue();
      expect(native.isSpeaking, isTrue);
      await engine.stop();
      await speaking;
      expect(native.callsTo('stop'), hasLength(1));
      expect(native.isSpeaking, isFalse);
    });

    test('cancels an utterance still waiting for the model', () async {
      final loaded = Completer<Object?>();
      native.onLoad = () => loaded.future;
      final speaking = engine.speak('Hello there chat');
      await pumpEventQueue();
      await engine.stop();
      loaded.complete('supertonic-1');
      await speaking;
      expect(native.callsTo('speak'), isEmpty);
      // Later utterances still speak.
      await speakNow('Hello again chat');
      expect(native.callsTo('speak'), hasLength(1));
    });

    test("leaves other engines' speech alone", () async {
      await engine.stop();
      expect(native.callsTo('stop'), isEmpty);
    });
  });

  group('events', () {
    test("carry this engine's firstAudio and done", () async {
      final other = NeuralTtsEngine(supertonicPack(), platform: platform);
      final events = <OnnxTtsEvent>[];
      final sub = engine.events.listen(events.add);
      await pumpEventQueue();

      await speakNow('Hello there chat');
      native.emit('someone-else', 'firstAudio');
      final otherSpeaking = other.speak('Other engine speaking');
      await pumpEventQueue();
      native.finish();
      await otherSpeaking;
      await pumpEventQueue();
      await sub.cancel();

      expect(events.map((e) => e.type),
          [OnnxTtsEventType.firstAudio, OnnxTtsEventType.done]);
      expect(events.map((e) => e.utteranceId).toSet(),
          {(native.callsTo('speak').first.arguments as Map)['utteranceId']});
    });

    test('carry errors', () async {
      final events = <OnnxTtsEvent>[];
      final sub = engine.events.listen(events.add);
      await pumpEventQueue();
      native.onSpeak = (call) async {
        native.emit((call.arguments as Map)['utteranceId'] as String, 'error',
            message: 'boom');
        throw PlatformException(code: 'speak_failed', message: 'boom');
      };
      await expectLater(
          engine.speak('Hello there chat'), throwsA(isA<PlatformException>()));
      await pumpEventQueue();
      await sub.cancel();
      expect(events.single.type, OnnxTtsEventType.error);
      expect(events.single.message, 'boom');
    });
  });

  group('voices', () {
    test("lists each speaker in each of the pack's languages", () async {
      final voices = await engine.voices();
      expect(voices, hasLength(6));
      expect(voices.first, const TtsVoice(id: 'F1', name: 'F1', locale: 'en'));
      expect(await engine.voices(language: 'ko'), const [
        TtsVoice(id: 'F1', name: 'F1', locale: 'ko'),
        TtsVoice(id: 'M1', name: 'M1', locale: 'ko'),
      ]);
      expect(await engine.voices(language: 'fr'), isEmpty);
      expect(native.calls, isEmpty, reason: 'no need to load the model');
    });

    test('uses the voice style file names as ids', () async {
      engine = NeuralTtsEngine(
          supertonicPack(speakers: const [
            VoicePackSpeaker(index: 1, name: 'Marco'),
          ]),
          platform: platform);
      expect((await engine.voices(language: 'en')).single,
          const TtsVoice(id: 'M1', name: 'Marco', locale: 'en'));
    });

    test('keeps a speaker to its own language', () async {
      engine = NeuralTtsEngine(
          supertonicPack(speakers: const [
            VoicePackSpeaker(index: 0, name: 'F1', language: 'es'),
          ]),
          platform: platform);
      expect(await engine.voices(),
          const [TtsVoice(id: 'F1', name: 'F1', locale: 'es')]);
    });
  });

  group('release and dispose', () {
    test('release unloads, and the next speak loads again', () async {
      await speakNow('Hello there chat');
      await engine.release();
      expect(native.argsOf('unload'), {'handle': 'supertonic-1'});
      expect(engine.isLoaded, isFalse);

      native.onLoad = () async => 'supertonic-2';
      await speakNow('Hello again chat');
      expect(native.callsTo('load'), hasLength(2));
      expect(native.callsTo('speak').last.arguments['handle'], 'supertonic-2');
    });

    test('release stops the utterance first', () async {
      final speaking = engine.speak('Hello there chat');
      await pumpEventQueue();
      await engine.release();
      await speaking;
      expect(native.calls.map((c) => c.method),
          ['load', 'speak', 'stop', 'unload']);
    });

    test('release without a model does nothing', () async {
      await engine.release();
      expect(native.calls, isEmpty);
    });

    test('release after a failed load does nothing', () async {
      native.onLoad = () async => throw PlatformException(code: 'load_failed');
      await expectLater(engine.load(), throwsA(isA<NeuralTtsLoadException>()));
      await engine.release();
      expect(native.callsTo('unload'), isEmpty);
    });

    test('dispose unloads once', () async {
      await speakNow('Hello there chat');
      await engine.dispose();
      await engine.dispose();
      expect(native.callsTo('unload'), hasLength(1));
    });
  });
}
