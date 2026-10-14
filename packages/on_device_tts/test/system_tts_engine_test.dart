import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall call) handler;

  setUp(() {
    calls = [];
    handler = (call) async => 1;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  List<String> methods() => calls.map((call) => call.method).toList();

  test('shares the audio session', () async {
    SystemTtsEngine();
    await pumpEventQueue();
    expect(methods(), contains('setSharedInstance'));
    expect(calls.firstWhere((c) => c.method == 'setSharedInstance').arguments,
        isTrue);
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
    // the languages the fake platform has voices for.
    var available = {'en', 'es', 'ja', 'pt'};

    setUp(() {
      available = {'en', 'es', 'ja', 'pt'};
      handler = (call) async {
        if (call.method == 'setLanguage') {
          return available.contains(call.arguments) ? 1 : 0;
        }
        return 1;
      };
    });

    List<Object?> languageCalls() => [
          for (final call in calls)
            if (call.method == 'setLanguage' || call.method == 'clearVoice')
              call.method == 'clearVoice' ? 'clearVoice' : call.arguments,
        ];

    test('sets the language only when it changes', () async {
      final engine = SystemTtsEngine(platformLanguage: () => null);
      await pumpEventQueue();
      calls.clear();

      await engine.speak('hola', language: 'es');
      await engine.speak('otra vez', language: 'es');
      await engine.speak('konnichiwa', language: 'ja');
      expect(languageCalls(), ['es', 'ja']);
      // set before speaking.
      expect(methods().indexOf('setLanguage'),
          lessThan(methods().indexOf('speak')));
    });

    test('falls back to the primary language, then the default voice',
        () async {
      final engine = SystemTtsEngine(platformLanguage: () => null);
      await pumpEventQueue();
      calls.clear();

      await engine.speak('oi', language: 'pt-BR');
      expect(languageCalls(), ['pt-BR', 'pt']);

      calls.clear();
      await engine.speak('ni hao', language: 'zh');
      expect(languageCalls(), ['zh', 'clearVoice']);
    });

    test('goes back to the default voice without a language', () async {
      final engine = SystemTtsEngine(platformLanguage: () => null);
      await pumpEventQueue();
      calls.clear();

      await engine.speak('hello');
      expect(languageCalls(), isEmpty, reason: 'already the default');

      await engine.speak('hola', language: 'es');
      await engine.speak('hello');
      expect(languageCalls(), ['es', 'clearVoice']);
    });

    test('restores the platform language where clearing the voice does not',
        () async {
      final engine = SystemTtsEngine(platformLanguage: () => 'en-US');
      await pumpEventQueue();
      calls.clear();

      await engine.speak('hola', language: 'es');
      await engine.speak('hello');
      expect(languageCalls(), ['es', 'clearVoice', 'en-US']);
    });

    test('a voice wins over the language', () async {
      final engine = SystemTtsEngine(platformLanguage: () => null);
      await pumpEventQueue();
      calls.clear();
      const voice = TtsVoice(id: 'en-gb-x', name: 'en-gb-x', locale: 'en-GB');

      await engine.speak('one', voice: voice, language: 'es');
      expect(methods(), isNot(contains('setLanguage')));
      expect(methods(), contains('setVoice'));

      calls.clear();
      await engine.speak('dos', language: 'es');
      expect(languageCalls(), ['es']);
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
      expect((await engine.voices(language: 'en')).map((v) => v.name),
          ['Samantha', 'Daniel']);
      expect((await engine.voices(language: 'en-GB')).map((v) => v.name),
          ['Daniel']);
      expect(await engine.voices(language: 'fr'), isEmpty);
    });

    test('is empty when the platform has none', () async {
      handler = (call) async => null;
      expect(await SystemTtsEngine().voices(), isEmpty);
    });
  });
}
