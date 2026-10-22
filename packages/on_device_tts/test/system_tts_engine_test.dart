import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
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
      handler = (call) async => call.method != 'setLanguage' ||
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
    late FakeAudioPlayer player;
    late SystemTtsEngine engine;

    setUp(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      directory = await Directory.systemTemp.createTemp('system-tts-test-');
      player = FakeAudioPlayer();
      engine = SystemTtsEngine(
        audioPlayer: player,
        tempDirectory: () async => directory,
      );
      handler = (call) async {
        if (call.method == 'synthesizeToFile') {
          await File(call.arguments['fileName'] as String).writeAsBytes([1, 2]);
        }
        return 1;
      };
    });

    tearDown(() async {
      await engine.dispose();
      await player.states.close();
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
        await player.pathReady.future.timeout(
          const Duration(seconds: 5),
        );
        expect(player.paths, hasLength(1));
        final synthesis = calls.singleWhere(
          (c) => c.method == 'synthesizeToFile',
        );
        expect(synthesis.arguments, {
          'text': 'hola',
          'fileName': player.paths.single,
          'isFullPath': true,
        });
        expect(File(player.paths.single).existsSync(), isTrue);
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
        player.complete();
        await speaking;
        expect(player.stopCount, 1);
        expect(directory.listSync(), isEmpty);
      },
    );

    test(
      'waits for completion even when play returns immediately, repeatedly',
      () async {
        for (var i = 0; i < 3; i++) {
          var finished = false;
          final speaking =
              engine.speak('hello $i').then((_) => finished = true);
          await pumpEventQueue(times: 100);
          expect(player.playCount, i + 1);
          expect(finished, isFalse);
          player.complete();
          await speaking;
          expect(player.stopCount, i + 1);
          expect(directory.listSync(), isEmpty);
        }
        expect(player.paths.toSet(), hasLength(3));
      },
    );

    test('stop releases playback and the next utterance can speak', () async {
      final speaking = engine.speak('first');
      await pumpEventQueue(times: 100);
      await engine.stop();
      await speaking;
      expect(directory.listSync(), isEmpty);
      final next = engine.speak('next');
      await pumpEventQueue(times: 100);
      expect(player.playCount, 2);
      player.complete();
      await next;
    });

    test('stop releases stalled synthesis without playing it later', () async {
      final synthesis = Completer<Object?>();
      final normalHandler = handler;
      handler = (call) => call.method == 'synthesizeToFile'
          ? synthesis.future
          : normalHandler(call);
      final speaking = engine.speak('canceled');
      await pumpEventQueue(times: 100);
      expect(methods(), contains('synthesizeToFile'));
      await engine.stop();
      await speaking;
      expect(player.playCount, 0);
      expect(directory.listSync(), isEmpty);
      synthesis.complete(1);
      await pumpEventQueue();
      expect(player.playCount, 0);
      handler = normalHandler;
      final next = engine.speak('next');
      await pumpEventQueue(times: 100);
      player.complete();
      await next;
      expect(player.playCount, 1);
    });

    test('synthesis failure throws and removes the temporary file', () async {
      handler = (call) async => call.method == 'synthesizeToFile' ? 0 : 1;
      await expectLater(engine.speak('failed'), throwsStateError);
      expect(player.playCount, 0);
      expect(directory.listSync(), isEmpty);
    });

    test('playback failure stops the player and removes the file', () async {
      player.playError = StateError('play failed');
      await expectLater(engine.speak('failed'), throwsStateError);
      expect(player.stopCount, 1);
      expect(directory.listSync(), isEmpty);
    });

    test(
      'synthesis timeout stops the platform and permits the next utterance',
      () async {
        final synthesis = Completer<Object?>();
        final normalHandler = handler;
        handler = (call) => call.method == 'synthesizeToFile'
            ? synthesis.future
            : normalHandler(call);
        await expectLater(
          engine.speak('stalled'),
          throwsA(isA<TimeoutException>()),
        );
        expect(methods(), contains('stop'));
        expect(player.playCount, 0);
        expect(directory.listSync(), isEmpty);
        synthesis.complete(1);
        handler = normalHandler;
        final next = engine.speak('next');
        await pumpEventQueue(times: 100);
        player.complete();
        await next;
        expect(player.playCount, 1);
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test('playback timeout releases the queue and cleans up', () async {
      await expectLater(
        engine.speak('stalled'),
        throwsA(isA<TimeoutException>()),
      );
      expect(player.stopCount, 1);
      expect(directory.listSync(), isEmpty);
      final next = engine.speak('next');
      await pumpEventQueue(times: 100);
      player.complete();
      await next;
      expect(player.playCount, 2);
    });

    test('load failure stops the player and cleans up', () async {
      player.loadError = StateError('load failed');
      await expectLater(engine.speak('failed'), throwsStateError);
      expect(player.stopCount, 1);
      expect(directory.listSync(), isEmpty);
    });

    test('dispose releases stalled playback and disposes the player', () async {
      final speaking = engine.speak('hello');
      await pumpEventQueue(times: 100);
      await engine.dispose();
      await speaking;
      expect(player.disposed, isTrue);
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

/// Models play() returning immediately while audio is still playing.
class FakeAudioPlayer implements AudioPlayer {
  final Completer<void> pathReady = Completer<void>();
  final states = StreamController<ProcessingState>.broadcast(sync: true);
  final paths = <String>[];
  int playCount = 0;
  int stopCount = 0;
  bool disposed = false;
  Object? playError;
  Object? loadError;

  @override
  Stream<ProcessingState> get processingStateStream => states.stream;

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    paths.add(filePath);

    if (!pathReady.isCompleted) {
      pathReady.complete();
    }

    if (loadError != null) throw loadError!;
    return const Duration(seconds: 1);
  }

  @override
  Future<void> play() async {
    playCount++;
    if (playError != null) throw playError!;
  }

  void complete() => states.add(ProcessingState.completed);

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
