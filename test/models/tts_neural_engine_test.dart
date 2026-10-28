import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

FakeChatMessage chat(String text, int i) => FakeChatMessage(
  messageId: 'm$i',
  timestamp: DateTime(2024),
  author: FakeChatUser(userId: '$i', login: 'user$i'),
  message: text,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  final spanish = lookupAppLocalizations(const Locale('es'));
  late SpeechLog log;
  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late List<Object> errors;
  late TtsModel model;

  setUp(() {
    log = SpeechLog();
    system = FakeTtsEngine(log: log, name: 'system');
    neural = FakeTtsEngine(
      log: log,
      name: 'neural',
      availableVoices: packVoices(['en', 'es', 'ja']),
    );
    errors = [];
    model = TtsModel.fromJson(
      {'language': 'es'},
      engine: system,
      reportError: (error, _) => errors.add(error),
    );
    model.neuralEngine = neural;
    model.setMode(l10n, TtsMode.enabled);
  });

  /// Lets every held utterance finish, a few times over.
  Future<void> drain() async {
    for (var i = 0; i < 30; i++) {
      for (final engine in [system, neural]) {
        engine.finishSpeaking();
      }
      await pumpEventQueue();
    }
  }

  test("speaks with the neural engine in the message's language", () async {
    final japanese = Channel(Providers.kick, '9', 'jp');
    model.setChannelLanguage(japanese, Language('ja'));
    model.speed = 0.8;
    model.say(l10n, chat('konnichiwa', 1)..channel = japanese);
    model.say(l10n, chat('hola', 2));
    await pumpEventQueue();

    expect(neural.spoken, [
      spanish.textToSpeechEnabled,
      lookupAppLocalizations(
        const Locale('ja'),
      ).saidMessage('user1', 'konnichiwa'),
      spanish.saidMessage('user2', 'hola'),
    ]);
    expect(neural.utterances.map((u) => u.language), [
      'es',
      'ja',
      'es',
    ], reason: 'announcements follow the reading language');
    expect(neural.utterances.last.rate, 0.8);
    expect(system.spoken, isEmpty);
  });

  test(
    'reads a message the neural engine fails with the system voice',
    () async {
      await pumpEventQueue();
      neural.failNext = PlatformException(code: 'speak_failed');
      model.say(l10n, chat('first', 1));
      model.say(l10n, chat('second', 2));
      await pumpEventQueue();

      expect(system.spoken, [spanish.saidMessage('user1', 'first')]);
      expect(neural.spoken.last, spanish.saidMessage('user2', 'second'));
      expect(errors.single, isA<PlatformException>());

      // but not a message unsaid in the meantime.
      neural.onSpeak = (_) async {
        model.unsay('m3');
        throw PlatformException(code: 'speak_failed');
      };
      model.say(l10n, chat('third', 3));
      await pumpEventQueue();
      expect(system.spoken, hasLength(1));
    },
  );

  test('a replaced engine finishes its message and is disposed before the '
      'next one starts', () async {
    final next = FakeTtsEngine(
      log: log,
      name: 'next',
      availableVoices: neural.availableVoices,
    );
    neural.holdSpeech = true;
    model.say(l10n, chat('first', 1));
    await pumpEventQueue();

    model.neuralEngine = next;
    await pumpEventQueue();
    expect(
      (neural.isDisposed, neural.stopCount),
      (false, 0),
      reason: 'not cut off',
    );

    await drain();
    expect(log.events, [
      'neural: ${spanish.textToSpeechEnabled}',
      'neural dispose',
      'next: ${spanish.saidMessage('user1', 'first')}',
    ]);
    expect(log.maxSpeaking, 1);

    // with nothing queued, a removed engine goes at once.
    model.neuralEngine = null;
    await pumpEventQueue();
    expect(next.isDisposed, isTrue);
  });

  test('the backlog cutoff stops the neural engine', () async {
    neural.holdSpeech = true;
    await pumpEventQueue();
    for (var i = 0; i < 25; i++) {
      model.say(l10n, chat('message $i', i));
    }
    await drain();

    expect(model.mode, TtsMode.disabled);
    expect(neural.stopCount, greaterThan(0));
    expect(neural.spoken.last, spanish.textToSpeechTooManyMessages);
    expect(log.maxSpeaking, 1);
  });

  test('disposing the model disposes every engine', () {
    model.dispose();
    expect((neural.isDisposed, system.isDisposed), (true, true));
  });
}
