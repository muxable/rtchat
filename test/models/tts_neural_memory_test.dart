import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

FakeChatMessage chat(String text, int i) => FakeChatMessage(
    messageId: 'm$i',
    timestamp: DateTime(2024),
    author: FakeChatUser(userId: '$i', login: 'user$i'),
    message: text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late List<Object> errors;
  late TtsModel model;

  setUp(() {
    system = FakeTtsEngine();
    neural = FakeTtsEngine(availableVoices: packVoices(['en']));
    errors = [];
    model = TtsModel.fromJson({'language': 'en'},
        engine: system,
        reportError: (error, _) => errors.add(error),
        neuralIdleTimeout: const Duration(minutes: 5))
      ..neuralEngine = neural
      ..setMode(l10n, TtsMode.enabled);
  });

  tearDown(() => model.dispose());

  group('releaseNeuralModels', () {
    test('waits for the message being read, then the next one reloads',
        () async {
      neural.holdSpeech = true;
      model.say(l10n, chat('first', 1));
      model.say(l10n, chat('second', 2));
      await pumpEventQueue();

      var released = false;
      model.releaseNeuralModels().then((_) => released = true);
      model.releaseNeuralModels();
      await pumpEventQueue();
      expect((neural.releaseCount, neural.stopCount), (0, 0),
          reason: 'not cut off');

      neural.finishSpeaking();
      await pumpEventQueue();
      expect((released, neural.releaseCount), (true, 1));
      neural.finishSpeaking();
      await pumpEventQueue();
      expect(neural.spoken, hasLength(3), reason: 'nothing dropped');
      expect(system.spoken, isEmpty);
    });

    test('a failed release is reported, not thrown', () async {
      await pumpEventQueue();
      model.neuralEngine = _FailingReleaseEngine();
      await model.releaseNeuralModels();
      expect(errors.single, isA<StateError>());
    });
  });

  test('turning TTS off releases once "disabled" has been read', () async {
    await pumpEventQueue();
    neural.holdSpeech = true;
    model.setMode(l10n, TtsMode.disabled);
    await pumpEventQueue();
    expect(neural.releaseCount, 0);
    // turned back on in the meantime: the model stays.
    model.setMode(l10n, TtsMode.enabled);
    neural.holdSpeech = false;
    neural.finishSpeaking();
    await pumpEventQueue();
    expect(neural.releaseCount, 0);

    model.setMode(l10n, TtsMode.disabled);
    await pumpEventQueue();
    expect(neural.releaseCount, 1);
  });

  test('the backlog cutoff releases too', () async {
    await pumpEventQueue();
    neural.holdSpeech = true;
    for (var i = 0; i < 25; i++) {
      model.say(l10n, chat('message $i', i));
    }
    for (var i = 0; i < 5; i++) {
      neural.finishSpeaking();
      await pumpEventQueue();
    }
    expect(model.mode, TtsMode.disabled);
    expect(neural.releaseCount, 1);
  });

  test('releases after a quiet spell, and each message restarts the clock',
      () async {
    model.dispose();
    model = TtsModel.fromJson({'language': 'en'},
        engine: system, neuralIdleTimeout: const Duration(milliseconds: 200))
      ..neuralEngine = neural
      ..setMode(l10n, TtsMode.enabled);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    model.say(l10n, chat('hello', 1));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(neural.releaseCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(neural.releaseCount, 1);
  });

  group('fallback', () {
    test(
        'a model that fails to load reads with the system voices from then '
        'on, with a one-time notice', () async {
      await pumpEventQueue();
      neural.failNext = NeuralTtsLoadException(
          PlatformException(code: 'load_failed', message: 'OOM'));
      model.say(l10n, chat('first', 1));
      model.say(l10n, chat('second', 2));
      await pumpEventQueue();

      expect(system.spoken, ['user1 said: first', 'user2 said: second']);
      expect(model.neuralFallback, NeuralTtsFallback.loadFailed);
      expect(model.isNeuralFallbackNoticePending, isTrue);
      expect(neural.releaseCount, 1);
      model.acknowledgeNeuralFallback();
      expect(model.isNeuralFallbackNoticePending, isFalse);
      errors.clear();

      // a new engine gets another chance.
      model.neuralEngine =
          FakeTtsEngine(availableVoices: neural.availableVoices);
      expect(model.neuralFallback, isNull);
    });

    test('other neural errors only fall back for that message', () async {
      await pumpEventQueue();
      neural.failNext = PlatformException(code: 'speak_failed');
      model.say(l10n, chat('first', 1));
      model.say(l10n, chat('second', 2));
      await pumpEventQueue();
      expect(system.spoken, ['user1 said: first']);
      expect(model.neuralFallback, isNull);
    });

    test('a low-memory device keeps the system voices for good', () async {
      model.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      model.neuralEngine =
          FakeTtsEngine(availableVoices: neural.availableVoices);
      model.say(l10n, chat('hello', 1));
      await pumpEventQueue();
      expect(model.neuralFallback, NeuralTtsFallback.lowMemoryDevice);
      expect(system.spoken.last, 'user1 said: hello');
    });
  });
}

class _FailingReleaseEngine extends FakeTtsEngine {
  @override
  Future<void> release() async => throw StateError('release failed');
}
