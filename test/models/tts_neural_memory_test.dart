import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';

import '../fakes/fake_tts_engine.dart';

TwitchMessageModel message(String text, int i) => TwitchMessageModel(
    messageId: 'm$i',
    author:
        TwitchUserModel(userId: '$i', login: 'user$i', displayName: 'User$i'),
    tags: const {},
    annotations: const TwitchMessageAnnotationsModel(
        isAction: false, isFirstTimeChatter: false, announcement: null),
    thirdPartyEmotes: const [],
    timestamp: DateTime(2024),
    message: text,
    deleted: false,
    channelId: 'placeholder');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late List<Object> errors;
  late TtsModel model;

  TtsModel createModel({Duration idle = const Duration(hours: 1)}) =>
      TtsModel.fromJson({'language': 'en'},
          engine: system,
          reportError: (error, _) => errors.add(error),
          neuralIdleTimeout: idle);

  setUp(() {
    system = FakeTtsEngine();
    neural = FakeTtsEngine(availableVoices: packVoices(['en']));
    errors = [];
    model = createModel()..neuralEngine = neural;
  });

  tearDown(() => model.dispose());

  /// Turns TTS on and lets "Text to speech enabled" be read.
  Future<void> enable() async {
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
  }

  group('memory pressure', () {
    test('releases the models, and the next message loads them again',
        () async {
      await enable();
      model.say(l10n, message('first', 1));
      await pumpEventQueue();
      expect(neural.isLoaded, isTrue);

      await model.releaseNeuralModels();
      expect(neural.releaseCount, 1);
      expect(neural.isLoaded, isFalse);

      model.say(l10n, message('second', 2));
      await pumpEventQueue();
      expect(neural.spoken.last, 'User2 said: second');
      expect(neural.loadCount, 2);
      expect(system.spoken, isEmpty);
    });

    test("waits for the message being read rather than cut it off", () async {
      await enable();
      neural.holdSpeech = true;
      model.say(l10n, message('first', 1));
      model.say(l10n, message('second', 2));
      await pumpEventQueue();

      var released = false;
      model.releaseNeuralModels().then((_) => released = true);
      await pumpEventQueue();
      expect(neural.releaseCount, 0);
      expect(neural.stopCount, 0);

      neural.finishSpeaking();
      await pumpEventQueue();
      expect(released, isTrue);
      expect(neural.releaseCount, 1);
      // the next message was read after the release, by a reloaded model.
      expect(neural.spoken.last, 'User2 said: second');
      expect(neural.isLoaded, isTrue);
      neural.finishSpeaking();
      await pumpEventQueue();
      expect(neural.spoken, hasLength(3), reason: 'nothing dropped');
    });

    test('several releases during a message release once after it', () async {
      await enable();
      neural.holdSpeech = true;
      model.say(l10n, message('first', 1));
      await pumpEventQueue();
      model.releaseNeuralModels();
      model.releaseNeuralModels();
      neural.finishSpeaking();
      await pumpEventQueue();
      expect(neural.releaseCount, 1);
    });

    test('a failed release is reported, not thrown', () async {
      final failing = _FailingReleaseEngine();
      model.neuralEngine = failing;
      await model.releaseNeuralModels();
      expect(errors.single, isA<StateError>());
    });
  });

  group('turning TTS off', () {
    test('releases the models once "disabled" has been read', () async {
      await enable();
      neural.holdSpeech = true;
      model.setMode(l10n, TtsMode.disabled);
      await pumpEventQueue();
      expect(neural.spoken.last, 'Text to speech disabled');
      expect(neural.releaseCount, 0, reason: 'still reading');

      neural.finishSpeaking();
      await pumpEventQueue();
      expect(neural.releaseCount, 1);
      expect(neural.isLoaded, isFalse);
    });

    test('turning it back on in the meantime keeps the models', () async {
      await enable();
      neural.holdSpeech = true;
      model.setMode(l10n, TtsMode.disabled);
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      for (var i = 0; i < 3; i++) {
        neural.finishSpeaking();
        await pumpEventQueue();
      }
      expect(neural.releaseCount, 0);
    });

    test('the backlog cutoff releases them too', () async {
      await enable();
      neural.holdSpeech = true;
      for (var i = 0; i < 25; i++) {
        model.say(l10n, message('message $i', i));
      }
      for (var i = 0; i < 5; i++) {
        neural.finishSpeaking();
        await pumpEventQueue();
      }
      expect(model.mode, TtsMode.disabled);
      expect(neural.releaseCount, 1);
    });
  });

  group('idle timeout', () {
    setUp(() {
      model.dispose();
      model = createModel(idle: const Duration(milliseconds: 50))
        ..neuralEngine = neural;
    });

    test('releases the models after a quiet spell', () async {
      await enable();
      model.say(l10n, message('first', 1));
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(neural.releaseCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(neural.releaseCount, 1);
      expect(neural.isLoaded, isFalse);

      // and not again while nothing is said.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(neural.releaseCount, 1);
    });

    test('each message restarts the timer', () async {
      await enable();
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        model.say(l10n, message('message $i', i));
        await pumpEventQueue();
      }
      expect(neural.releaseCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(neural.releaseCount, 1);
    });

    test("doesn't run while a message is being read", () async {
      await enable();
      neural.holdSpeech = true;
      model.say(l10n, message('a long one', 1));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(neural.releaseCount, 0);
      neural.finishSpeaking();
    });

    test("doesn't start when only the system voices spoke", () async {
      model.neuralEngine = null;
      await enable();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(neural.releaseCount, 0);
    });

    test('the default is five minutes', () {
      expect(TtsModel.defaultNeuralIdleTimeout, const Duration(minutes: 5));
      expect(TtsModel.fromJson({}, engine: system).neuralIdleTimeout,
          TtsModel.defaultNeuralIdleTimeout);
    });
  });

  group('load failure fallback', () {
    test('reads with the system voices for the rest of the session', () async {
      neural.failNext =
          NeuralTtsLoadException('out of memory', Exception('OOM'));
      await enable();
      expect(system.spoken, ['Text to speech enabled']);
      expect(model.neuralFallback, NeuralTtsFallback.loadFailed);
      expect(errors.single, isA<NeuralTtsLoadException>());

      model.say(l10n, message('first', 1));
      model.say(l10n, message('second', 2));
      await pumpEventQueue();
      expect(
          system.spoken.skip(1), ['User1 said: first', 'User2 said: second']);
      expect(neural.spoken, isEmpty, reason: 'no more load attempts');
      expect(errors, hasLength(1));
    });

    test('raises a one-time notice', () async {
      var notified = 0;
      model.addListener(() => notified++);
      neural.failNext = NeuralTtsLoadException('oom', Exception('OOM'));
      await enable();
      expect(model.isNeuralFallbackNoticePending, isTrue);
      expect(notified, greaterThan(0));

      model.acknowledgeNeuralFallback();
      expect(model.isNeuralFallbackNoticePending, isFalse);

      // another failure in the same session doesn't raise it again.
      model.fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      expect(model.isNeuralFallbackNoticePending, isFalse);
    });

    test('other neural errors only fall back for that message', () async {
      neural.failNext = PlatformException(code: 'speak_failed');
      await enable();
      expect(system.spoken, ['Text to speech enabled']);
      expect(model.neuralFallback, isNull);
      expect(model.isNeuralFallbackNoticePending, isFalse);
      model.say(l10n, message('first', 1));
      await pumpEventQueue();
      expect(neural.spoken, ['User1 said: first']);
    });

    test('new neural engines get another chance', () async {
      neural.failNext = NeuralTtsLoadException('oom', Exception('OOM'));
      await enable();
      expect(model.neuralFallback, NeuralTtsFallback.loadFailed);

      final other = FakeTtsEngine(availableVoices: packVoices(['en']));
      model.neuralEngine = other;
      expect(model.neuralFallback, isNull);
      model.say(l10n, message('first', 1));
      await pumpEventQueue();
      expect(other.spoken, ['User1 said: first']);
    });

    test('a low-memory device reads with the system voices', () async {
      model.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      expect(model.neuralFallback, NeuralTtsFallback.lowMemoryDevice);
      expect(model.isNeuralFallbackNoticePending, isTrue);
      await enable();
      expect(system.spoken, ['Text to speech enabled']);
      expect(neural.spoken, isEmpty);

      // installing a pack doesn't change the device.
      model.neuralEngine = FakeTtsEngine(availableVoices: packVoices(['en']));
      expect(model.neuralFallback, NeuralTtsFallback.lowMemoryDevice);
    });
  });
}

class _FailingReleaseEngine extends FakeTtsEngine {
  @override
  Future<void> release() async => throw StateError('release failed');
}
