import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(OnnxTtsPlatform.methodChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall call) handler;

  setUp(() {
    calls = [];
    handler = (call) async => null;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final platform = OnnxTtsPlatform();

  test('load sends the contract arguments and returns the handle', () async {
    handler = (call) async => 'supertonic-1';
    final handle = await platform.load(
        modelDir: '/models/st3', numThreads: 4, provider: OnnxProvider.xnnpack);
    expect(handle, 'supertonic-1');
    expect(calls.single.method, 'load');
    expect(calls.single.arguments, {
      'modelType': 'supertonic',
      'modelDir': '/models/st3',
      'numThreads': 4,
      'provider': 'xnnpack',
    });
  });

  test('load failures surface as PlatformExceptions', () async {
    handler = (call) async =>
        throw PlatformException(code: 'load_failed', message: 'missing');
    await expectLater(
        platform.load(modelDir: '/nope'),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'load_failed')));
  });

  test('voices parses the voice maps', () async {
    handler = (call) async => [
          {'id': 'F1', 'name': 'F1'},
          {'id': 'x', 'name': 'X', 'language': 'en'},
        ];
    expect(await platform.voices('h'), const [
      OnnxVoice(id: 'F1', name: 'F1'),
      OnnxVoice(id: 'x', name: 'X', language: 'en'),
    ]);
    expect(calls.single.arguments, {'handle': 'h'});
  });

  test('speak sends segments with defaults', () async {
    await platform.speak(
        handle: 'h',
        utteranceId: 'u1',
        segments: ['a,', 'b.'],
        language: 'en',
        voiceId: 'M1');
    expect(calls.single.method, 'speak');
    expect(calls.single.arguments, {
      'handle': 'h',
      'utteranceId': 'u1',
      'segments': ['a,', 'b.'],
      'language': 'en',
      'voiceId': 'M1',
      'speed': 1.0,
      'steps': 5,
    });
  });

  test('speak completes when the platform does', () async {
    final done = Completer<Object?>();
    handler = (call) => done.future;
    var finished = false;
    final speaking = platform
        .speak(
            handle: 'h',
            utteranceId: 'u',
            segments: ['hi'],
            language: 'en',
            voiceId: 'F1')
        .then((_) => finished = true);
    await pumpEventQueue();
    expect(finished, isFalse);
    done.complete(null);
    await speaking;
    expect(finished, isTrue);
  });

  test('synthesize returns PCM and passes the seed only when set', () async {
    handler = (call) async => {
          'sampleRate': 44100,
          'pcm': Float32List.fromList(List.filled(44100, 0.5)),
        };
    final audio = await platform.synthesize(
        handle: 'h', text: 't', language: 'ru', voiceId: 'F2', noiseSeed: 7);
    expect(audio.sampleRate, 44100);
    expect(audio.duration, const Duration(seconds: 1));
    expect(calls.last.arguments['noiseSeed'], 7);
    await platform.synthesize(
        handle: 'h', text: 't', language: 'ru', voiceId: 'F2', speed: 1.2);
    expect((calls.last.arguments as Map).containsKey('noiseSeed'), isFalse);
    expect(calls.last.arguments['speed'], 1.2);
  });

  test('stop and unload', () async {
    await platform.stop();
    await platform.unload('h');
    expect(calls.map((c) => c.method), ['stop', 'unload']);
    expect(calls.last.arguments, {'handle': 'h'});
  });

  test('parses events and drops unknown types', () {
    expect(
      OnnxTtsEvent.fromMap(
          {'utteranceId': 'u', 'type': 'firstAudio', 'elapsedMs': 120}),
      const OnnxTtsEvent(
          utteranceId: 'u',
          type: OnnxTtsEventType.firstAudio,
          elapsed: Duration(milliseconds: 120)),
    );
    expect(
      OnnxTtsEvent.fromMap({
        'utteranceId': 'u',
        'type': 'error',
        'elapsedMs': 5,
        'message': 'boom'
      })!
          .message,
      'boom',
    );
    expect(
        OnnxTtsEvent.fromMap(
            {'utteranceId': 'u', 'type': 'new', 'elapsedMs': 1}),
        isNull);
  });

  test('events come from the event channel', () async {
    messenger.setMockStreamHandler(
      const EventChannel(OnnxTtsPlatform.eventChannelName),
      MockStreamHandler.inline(onListen: (args, sink) {
        sink.success({'utteranceId': 'u', 'type': 'done', 'elapsedMs': 900});
        sink.success({'utteranceId': 'u', 'type': 'bogus', 'elapsedMs': 1});
        sink.endOfStream();
      }),
    );
    final events = await OnnxTtsPlatform().events.toList();
    expect(events.map((e) => e.type), [OnnxTtsEventType.done]);
    expect(events.single.elapsed, const Duration(milliseconds: 900));
  });

  test('OnnxTts wraps a handle', () async {
    handler = (call) async => call.method == 'load' ? 'supertonic-3' : null;
    final tts = await OnnxTts.load(modelDir: '/m', platform: platform);
    expect(tts.handle, 'supertonic-3');
    await tts.speak(['one'], language: 'en', voiceId: 'F1');
    await tts
        .speak(['two'], language: 'en', voiceId: 'F1', utteranceId: 'mine');
    final speaks = calls.where((c) => c.method == 'speak').toList();
    expect(speaks[0].arguments['handle'], 'supertonic-3');
    expect(speaks[0].arguments['utteranceId'], 'supertonic-3-0');
    expect(speaks[1].arguments['utteranceId'], 'mine');
    await tts.unload();
    expect(calls.last.method, 'unload');
  });

  test('OnnxTts uses the platform instance by default', () async {
    final previous = OnnxTtsPlatform.instance;
    final fake = _FakePlatform();
    OnnxTtsPlatform.instance = fake;
    addTearDown(() => OnnxTtsPlatform.instance = previous);
    final tts = await OnnxTts.load(modelDir: '/m');
    expect(tts.handle, 'fake');
    expect(fake.loadedDir, '/m');
  });
}

class _FakePlatform extends OnnxTtsPlatform {
  String? loadedDir;

  @override
  Future<String> load({
    String modelType = 'supertonic',
    required String modelDir,
    int numThreads = 2,
    OnnxProvider provider = OnnxProvider.cpu,
  }) async {
    loadedDir = modelDir;
    return 'fake';
  }
}
