import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../fakes/fake_tts_engine.dart';

/// Records, across engines, what happens in order, and how many engines
/// speak at once.
class SpeechLog {
  final events = <String>[];
  var speaking = 0;
  var maxSpeaking = 0;
}

/// A [FakeTtsEngine] that logs to a shared [SpeechLog].
class LoggingEngine extends FakeTtsEngine {
  final String name;
  final SpeechLog log;

  LoggingEngine(this.name, this.log, {super.availableVoices});

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    log.speaking++;
    if (log.speaking > log.maxSpeaking) log.maxSpeaking = log.speaking;
    log.events.add('$name: $text');
    try {
      await super.speak(text,
          voice: voice, rate: rate, pitch: pitch, language: language);
    } finally {
      log.speaking--;
    }
  }

  @override
  Future<void> stop() {
    log.events.add('$name stop');
    return super.stop();
  }

  @override
  Future<void> dispose() {
    log.events.add('$name dispose');
    return super.dispose();
  }
}

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
  late SpeechLog log;
  late LoggingEngine system;
  late LoggingEngine neural;
  late List<Object> errors;
  late TtsModel model;

  setUp(() {
    log = SpeechLog();
    system = LoggingEngine('system', log);
    neural = LoggingEngine('neural', log,
        availableVoices: packVoices(['en', 'es', 'ja']));
    errors = [];
    model = TtsModel.fromJson({'language': 'es'},
        engine: system, reportError: (error, _) => errors.add(error));
  });

  /// Lets every held utterance finish, a few times over.
  Future<void> drain(List<FakeTtsEngine> engines) async {
    for (var i = 0; i < 30; i++) {
      for (final engine in engines) {
        engine.finishSpeaking();
      }
      await pumpEventQueue();
    }
  }

  test('speaks with the system voices without a neural engine', () async {
    model.setMode(l10n, TtsMode.enabled);
    model.say(l10n, message('hello', 1));
    await pumpEventQueue();
    expect(system.spoken, ['Text to speech enabled', 'User1 said: hello']);
    expect(model.neuralEngine, isNull);
  });

  test('speaks with the neural engine when there is one', () async {
    model.neuralEngine = neural;
    model.speed = 0.8;
    model.setMode(l10n, TtsMode.enabled);
    model.say(l10n, message('hola a todos', 1));
    await pumpEventQueue();

    expect(
        neural.spoken, ['Text to speech enabled', 'User1 said: hola a todos']);
    expect(system.spoken, isEmpty);
    expect(neural.utterances.last.language, 'es');
    expect(neural.utterances.last.rate, 0.8);
  });

  test("reads a message in its channel's language", () async {
    model.neuralEngine = neural;
    final japanese = Channel(Providers.kick, '9', 'jp');
    model.setChannelLanguage(japanese, Language('ja'));
    model.setMode(l10n, TtsMode.enabled);
    model.say(l10n, message('konnichiwa', 1)..channel = japanese);
    model.say(l10n, message('hola', 2));
    await pumpEventQueue();

    // "Text to speech enabled" is in the app's language.
    expect(neural.utterances.map((u) => u.language), ['en', 'ja', 'es']);
  });

  test('falls back to the system voice for a message the neural engine fails',
      () async {
    model.neuralEngine = neural;
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    neural.failNext = PlatformException(code: 'speak_failed');
    model.say(l10n, message('first', 1));
    model.say(l10n, message('second', 2));
    await pumpEventQueue();

    expect(system.spoken, ['User1 said: first']);
    expect(neural.spoken, ['Text to speech enabled', 'User2 said: second']);
    expect(errors.single,
        isA<PlatformException>().having((e) => e.code, 'code', 'speak_failed'));
  });

  test('falls back when the neural model cannot load', () async {
    model.neuralEngine = neural;
    neural.failNext = PlatformException(code: 'load_failed');
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    expect(system.spoken, ['Text to speech enabled']);
    expect(errors, hasLength(1));
  });

  test('does not fall back for a message unsaid while the neural engine failed',
      () async {
    model.neuralEngine = neural;
    neural.holdSpeech = true;
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    neural.finishSpeaking();
    neural.onSpeak = (text) async {
      model.unsay('m1');
      throw PlatformException(code: 'speak_failed');
    };
    model.say(l10n, message('first', 1));
    await pumpEventQueue();
    expect(system.spoken, isEmpty);
  });

  test(
      'a replaced engine finishes its message and is disposed before the '
      'next one starts', () async {
    final next =
        LoggingEngine('next', log, availableVoices: packVoices(['en', 'es']));
    model.neuralEngine = neural;
    neural.holdSpeech = true;
    next.holdSpeech = true;
    model.setMode(l10n, TtsMode.enabled);
    model.say(l10n, message('first', 1));
    model.say(l10n, message('second', 2));
    await pumpEventQueue();
    expect(log.events, ['neural: Text to speech enabled']);

    model.neuralEngine = next;
    await pumpEventQueue();
    expect(neural.isDisposed, isFalse, reason: 'still speaking');
    expect(neural.stopCount, 0, reason: 'not cut off');

    await drain([neural, next]);
    expect(log.events, [
      'neural: Text to speech enabled',
      'neural dispose',
      'next: User1 said: first',
      'next: User2 said: second',
    ]);
    expect(log.maxSpeaking, 1, reason: 'no overlapping speech');
  });

  test('a replaced engine is disposed when nothing is queued', () async {
    model.neuralEngine = neural;
    model.neuralEngine = null;
    await pumpEventQueue();
    expect(neural.isDisposed, isTrue);

    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    expect(system.spoken, ['Text to speech enabled']);
  });

  test('setting the same engine again keeps it', () async {
    model.neuralEngine = neural;
    model.neuralEngine = neural;
    await pumpEventQueue();
    expect(neural.isDisposed, isFalse);
  });

  test('the backlog cutoff stops the neural engine', () async {
    model.neuralEngine = neural;
    neural.holdSpeech = true;
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    for (var i = 0; i < 25; i++) {
      model.say(l10n, message('message $i', i));
    }
    await pumpEventQueue();
    await drain([neural]);

    expect(model.mode, TtsMode.disabled);
    expect(neural.stopCount, greaterThanOrEqualTo(1));
    expect(neural.spoken.last, l10n.textToSpeechTooManyMessages);
    expect(neural.spoken.where((s) => s.contains(' said: ')), isEmpty);
    expect(log.maxSpeaking, 1);
  });

  test('unsaid messages are skipped with the neural engine', () async {
    model.neuralEngine = neural;
    neural.holdSpeech = true;
    model.setMode(l10n, TtsMode.enabled);
    model.say(l10n, message('first', 1));
    model.say(l10n, message('second', 2));
    await pumpEventQueue();
    model.unsay('m1');
    await drain([neural]);
    expect(neural.spoken, ['Text to speech enabled', 'User2 said: second']);
  });

  test('disposing the model disposes every engine', () async {
    model.neuralEngine = neural;
    model.dispose();
    expect(neural.isDisposed, isTrue);
    expect(system.isDisposed, isTrue);
  });
}
