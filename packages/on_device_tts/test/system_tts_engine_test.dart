import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('on_device_tts/system');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall call) handler;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls = [];
    handler = (call) async => 1;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  List<String> methods() => calls.map((call) => call.method).toList();

  test('shares the audio session', () async {
    SystemTtsEngine();
    await pumpEventQueue();
    expect(methods(), contains('setSharedInstance'));
    expect(
      calls.firstWhere((c) => c.method == 'setSharedInstance').arguments,
      isTrue,
    );
  });

  test('speaks with the rate and pitch, waiting for completion', () async {
    final engine = SystemTtsEngine();
    await pumpEventQueue();
    calls.clear();

    await engine.speak('hello', rate: 0.8, pitch: 1.5);

    expect(methods(), [
      'setSpeechRate',
      'setPitch',
      'awaitSpeakCompletion',
      'speak',
    ]);
    expect(calls[0].arguments, 0.8);
    expect(calls[1].arguments, 1.5);
    expect(calls[2].arguments, isTrue);
    expect(calls[3].arguments, 'hello');
  });

  test('speak completes when the platform finishes speaking', () async {
    final done = Completer<Object?>();
    handler = (call) => call.method == 'speak' ? done.future : Future.value(1);
    final engine = SystemTtsEngine();

    var finished = false;
    final speaking = engine.speak('hello').then((_) => finished = true);
    await pumpEventQueue();
    expect(finished, isFalse);

    done.complete(1);
    await speaking;
    expect(finished, isTrue);
  });

  test('speak throws when the platform fails', () async {
    handler = (call) async {
      if (call.method == 'speak') throw PlatformException(code: 'failed');
      return 1;
    };
    final engine = SystemTtsEngine();
    await expectLater(engine.speak('hello'), throwsA(isA<PlatformException>()));
  });

  test('sets the voice only when it changes', () async {
    final engine = SystemTtsEngine();
    await pumpEventQueue();
    const voice = TtsVoice(id: 'en-gb-x', name: 'en-gb-x', locale: 'en-GB');

    calls.clear();
    await engine.speak('one');
    expect(methods(), isNot(contains('setVoice')));
    expect(methods(), isNot(contains('clearVoice')));

    calls.clear();
    await engine.speak('two', voice: voice);
    final setVoice = calls.singleWhere((c) => c.method == 'setVoice');
    expect(setVoice.arguments, {'name': 'en-gb-x', 'locale': 'en-GB'});

    calls.clear();
    await engine.speak('three', voice: voice);
    expect(methods(), isNot(contains('setVoice')));

    calls.clear();
    await engine.speak('four');
    expect(methods(), contains('clearVoice'));
  });

  group('language', () {
    setUp(() {
      // the platform has voices for these languages.
      handler =
          (call) async =>
              call.method != 'setLanguage' ||
                      {'en', 'es', 'ja', 'pt'}.contains(call.arguments)
                  ? 1
                  : 0;
    });

    List<Object?> languageCalls() => [
      for (final call in calls)
        if (call.method == 'setLanguage')
          call.arguments
        else if (call.method == 'clearVoice')
          'clearVoice',
    ];

    Future<SystemTtsEngine> engine({String? platformLanguage}) async {
      final engine = SystemTtsEngine(platformLanguage: () => platformLanguage);
      await pumpEventQueue();
      calls.clear();
      return engine;
    }

    test('sets the language before speaking, only when it changes', () async {
      final tts = await engine();
      await tts.speak('hola', language: 'es');
      await tts.speak('otra vez', language: 'es');
      await tts.speak('konnichiwa', language: 'ja');
      expect(languageCalls(), ['es', 'ja']);
      expect(
        methods().indexOf('setLanguage'),
        lessThan(methods().indexOf('speak')),
      );
    });

    test(
      'falls back to the primary language, then the default voice',
      () async {
        final tts = await engine();
        await tts.speak('oi', language: 'pt-BR');
        expect(languageCalls(), ['pt-BR', 'pt']);

        calls.clear();
        await tts.speak('ni hao', language: 'zh');
        expect(languageCalls(), ['zh', 'clearVoice']);
      },
    );

    test(
      'goes back to the default voice and platform language without one',
      () async {
        final tts = await engine(platformLanguage: 'en-US');
        await tts.speak('hello');
        expect(languageCalls(), isEmpty, reason: 'already the default');

        await tts.speak('hola', language: 'es');
        await tts.speak('hello');
        expect(languageCalls(), ['es', 'clearVoice', 'en-US']);
      },
    );

    test('a voice wins over the language', () async {
      final tts = await engine();
      const voice = TtsVoice(id: 'en-gb-x', name: 'en-gb-x', locale: 'en-GB');
      await tts.speak('one', voice: voice, language: 'es');
      expect(methods(), isNot(contains('setLanguage')));
      expect(methods(), contains('setVoice'));
    });
  });

  test('stop and dispose stop the platform', () async {
    final engine = SystemTtsEngine();
    await pumpEventQueue();

    calls.clear();
    await engine.stop();
    expect(methods(), ['stop']);

    calls.clear();
    await engine.dispose();
    expect(methods(), ['stop']);
  });

  group('Android in-process audio', () {
    late Directory directory;
    late SystemTtsEngine engine;
    // The files played, and the playback still going, if any.
    late List<String> played;
    Completer<Object?>? playback;
    late Future<Object?> Function(MethodCall call) normalHandler;

    void complete() {
      playback!.complete(1);
      playback = null;
    }

    setUp(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      directory = await Directory.systemTemp.createTemp('system-tts-test-');
      engine = SystemTtsEngine(tempDirectory: () async => directory);
      played = [];
      playback = null;
      normalHandler = (call) async {
        switch (call.method) {
          case 'synthesizeToFile':
            await File(
              call.arguments['fileName'] as String,
            ).writeAsBytes([1, 2]);
          case 'playFile':
            final path = call.arguments['path'] as String;
            played.add(path);
            expect(File(path).existsSync(), isTrue);
            playback = Completer();
            return playback!.future;
          case 'stop':
            // stopping cuts off file playback.
            playback?.complete(0);
            playback = null;
        }
        return 1;
      };
      handler = normalHandler;
    });

    tearDown(() async {
      await engine.dispose();
      await directory.delete(recursive: true);
    });

    test(
      'synthesizes full paths with the selected language, rate and pitch',
      () async {
        final speaking = engine.speak(
          'hola',
          language: 'es',
          rate: 0.8,
          pitch: 1.5,
        );
        await pumpEventQueue(times: 100);
        expect(played, hasLength(1));
        final synthesis = calls.singleWhere(
          (c) => c.method == 'synthesizeToFile',
        );
        expect(synthesis.arguments, {
          'text': 'hola',
          'fileName': played.single,
          'isFullPath': true,
        });
        expect(
          calls.singleWhere((c) => c.method == 'setLanguage').arguments,
          'es',
        );
        expect(
          calls.singleWhere((c) => c.method == 'setSpeechRate').arguments,
          0.8,
        );
        expect(calls.singleWhere((c) => c.method == 'setPitch').arguments, 1.5);
        expect(methods(), isNot(contains('speak')));
        expect(
          methods().indexOf('awaitSynthCompletion'),
          lessThan(methods().indexOf('synthesizeToFile')),
        );
        complete();
        await speaking;
        expect(directory.listSync(), isEmpty);
      },
    );

    test('waits for playback to finish, repeatedly', () async {
      for (var i = 0; i < 3; i++) {
        var finished = false;
        final speaking = engine.speak('hello $i').then((_) => finished = true);
        await pumpEventQueue(times: 100);
        expect(played, hasLength(i + 1));
        expect(finished, isFalse);
        complete();
        await speaking;
        expect(directory.listSync(), isEmpty);
      }
      expect(played.toSet(), hasLength(3));
    });

    test('stop releases playback and the next utterance can speak', () async {
      final speaking = engine.speak('first');
      await pumpEventQueue(times: 100);
      await engine.stop();
      await speaking;
      expect(directory.listSync(), isEmpty);
      final next = engine.speak('next');
      await pumpEventQueue(times: 100);
      expect(played, hasLength(2));
      complete();
      await next;
    });

    test('stop releases stalled synthesis without playing it later', () async {
      final synthesis = Completer<Object?>();
      handler =
          (call) =>
              call.method == 'synthesizeToFile'
                  ? synthesis.future
                  : normalHandler(call);
      final speaking = engine.speak('canceled');
      await pumpEventQueue(times: 100);
      expect(methods(), contains('synthesizeToFile'));
      await engine.stop();
      await speaking;
      expect(played, isEmpty);
      expect(directory.listSync(), isEmpty);
      synthesis.complete(1);
      await pumpEventQueue();
      expect(played, isEmpty);
      handler = normalHandler;
      final next = engine.speak('next');
      await pumpEventQueue(times: 100);
      complete();
      await next;
      expect(played, hasLength(1));
    });

    test('synthesis failure throws and removes the temporary file', () async {
      handler =
          (call) =>
              call.method == 'synthesizeToFile'
                  ? Future.value(0)
                  : normalHandler(call);
      await expectLater(engine.speak('failed'), throwsStateError);
      expect(played, isEmpty);
      expect(directory.listSync(), isEmpty);
    });

    test('playback failure throws and removes the file', () async {
      handler = (call) async {
        if (call.method == 'playFile') {
          throw PlatformException(code: 'PlaybackError');
        }
        return normalHandler(call);
      };
      await expectLater(
        engine.speak('failed'),
        throwsA(isA<PlatformException>()),
      );
      expect(directory.listSync(), isEmpty);
    });

    test(
      'synthesis timeout stops the platform and permits the next utterance',
      () async {
        final synthesis = Completer<Object?>();
        handler =
            (call) =>
                call.method == 'synthesizeToFile'
                    ? synthesis.future
                    : normalHandler(call);
        await expectLater(
          engine.speak('stalled'),
          throwsA(isA<TimeoutException>()),
        );
        expect(methods(), contains('stop'));
        expect(played, isEmpty);
        expect(directory.listSync(), isEmpty);
        synthesis.complete(1);
        handler = normalHandler;
        final next = engine.speak('next');
        await pumpEventQueue(times: 100);
        complete();
        await next;
        expect(played, hasLength(1));
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test('dispose releases playback', () async {
      final speaking = engine.speak('hello');
      await pumpEventQueue(times: 100);
      await engine.dispose();
      await speaking;
      expect(directory.listSync(), isEmpty);
      await expectLater(engine.speak('after dispose'), throwsStateError);
    });
  });

  group('voices', () {
    setUp(() {
      handler = (call) async {
        if (call.method == 'getVoices') {
          return [
            {'name': 'Samantha', 'locale': 'en-US'},
            {'name': 'Daniel', 'locale': 'en-GB'},
            {'name': 'Luciana', 'locale': 'pt-BR'},
            {'name': 'broken'},
            'not a voice',
          ];
        }
        return 1;
      };
    });

    test('lists every well-formed voice', () async {
      expect(await SystemTtsEngine().voices(), const [
        TtsVoice(id: 'Samantha', name: 'Samantha', locale: 'en-US'),
        TtsVoice(id: 'Daniel', name: 'Daniel', locale: 'en-GB'),
        TtsVoice(id: 'Luciana', name: 'Luciana', locale: 'pt-BR'),
      ]);
    });

    test('filters by language', () async {
      final engine = SystemTtsEngine();
      expect((await engine.voices(language: 'en')).map((v) => v.name), [
        'Samantha',
        'Daniel',
      ]);
      expect((await engine.voices(language: 'en-GB')).map((v) => v.name), [
        'Daniel',
      ]);
      expect(await engine.voices(language: 'fr'), isEmpty);
    });

    test('is empty when the platform has none', () async {
      handler = (call) async => null;
      expect(await SystemTtsEngine().voices(), isEmpty);
    });
  });
}
