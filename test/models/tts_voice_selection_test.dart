import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

var _messages = 0;

FakeChatMessage chat(String text, {String userId = '1', Channel? channel}) =>
    FakeChatMessage(
      messageId: 'm${_messages++}',
      timestamp: DateTime(2024),
      author: FakeChatUser(userId: userId, login: 'user$userId'),
      message: text,
    )..channel = channel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  final japanese = Channel(Providers.twitch, 'jp', 'jp');
  final chinese = Channel(Providers.twitch, 'zh', 'zh');
  final brazilian = Channel(Providers.kick, 'br', 'br');

  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late TtsModel model;

  TtsModel createModel(Map<String, dynamic> json) {
    final model =
        TtsModel.fromJson(
            json,
            engine: system,
            reportError: (error, _) => fail('$error'),
          )
          ..neuralEngine = neural
          ..setChannelLanguage(japanese, Language('ja'))
          ..setChannelLanguage(chinese, Language('zh'))
          ..setChannelLanguage(brazilian, Language('pt-BR'))
          ..setMode(l10n, TtsMode.enabled);
    return model;
  }

  setUp(() async {
    system = FakeTtsEngine();
    neural = FakeTtsEngine(
      availableVoices: packVoices(['en', 'es', 'ja', 'pt', 'fr']),
    );
    model = createModel({'language': 'en'});
    await pumpEventQueue();
    neural.utterances.clear(); // "Text to speech enabled"
  });

  test('routes each message to a neural voice for its language, or the '
      'system voices', () async {
    model.say(l10n, chat('konnichiwa', channel: japanese));
    model.say(l10n, chat('oi', channel: brazilian));
    model.say(l10n, chat('ni hao', channel: chinese));
    model.say(l10n, chat('hello'));
    await pumpEventQueue();

    expect(neural.utterances.map((u) => u.language), ['ja', 'pt', 'en']);
    expect(system.utterances.map((u) => (u.text, u.language)), [
      (
        lookupAppLocalizations(
          const Locale('zh'),
        ).saidMessage('user1', 'ni hao'),
        'zh',
      ),
    ]);
  });

  test('a chatter keeps their voice across languages and restarts', () async {
    model.say(l10n, chat('hello', userId: '7'));
    model.say(l10n, chat('konnichiwa', userId: '7', channel: japanese));
    model.say(l10n, chat('hi', userId: '1'));
    await pumpEventQueue();
    // fnv1a32('fake:7') % 10 == 9 and fnv1a32('fake:1') % 10 == 1.
    expect(neural.utterances.map((u) => u.voice?.id), ['M5', 'M5', 'F2']);

    neural = FakeTtsEngine(availableVoices: neural.availableVoices);
    final restarted = createModel(model.toJson());
    restarted.say(l10n, chat('hello again', userId: '7'));
    await pumpEventQueue();
    expect(neural.utterances.last.voice?.id, 'M5');
  });

  test('chatters are told apart by provider and user id, else login', () {
    expect(
      TtsModel.voiceKey(const TwitchUserModel(userId: '1', login: 'a')),
      'twitch:1',
    );
    expect(
      TtsModel.voiceKey(const TwitchUserModel(userId: '', login: 'Ab')),
      'twitch:login:ab',
    );
  });

  test('alerts use the chosen voice in the app language', () async {
    model.setVoice('en', 'M4');
    model.say(l10n, SystemMessageModel(text: 'hello')..channel = japanese);
    await pumpEventQueue();
    expect(neural.utterances.map((u) => (u.voice?.id, u.language)), [
      ('M4', 'en'),
    ]);
  });

  test(
    'without random voices, reads with the voice chosen per language',
    () async {
      model
        ..isRandomVoiceEnabled = false
        ..setVoice('pt', 'F2')
        ..setVoice('pt-BR', 'M5')
        ..setVoice('ja', 'gone');
      model.say(l10n, chat('hello'));
      model.say(l10n, chat('oi', channel: brazilian));
      model.say(l10n, chat('konnichiwa', channel: japanese));
      await pumpEventQueue();
      // the first voice by default, a region over its language, and the first
      // again for a voice the pack no longer has.
      expect(neural.utterances.map((u) => u.voice?.id), ['F1', 'M5', 'F1']);
    },
  );

  test('availableVoices and voiceFor', () async {
    expect(
      (await model.availableVoices('pt-BR')).map((v) => v.locale),
      everyElement('pt'),
    );
    expect(await model.availableVoices('zh'), isEmpty);
    expect((await model.voiceFor('fr'))?.id, 'F1');
    var notified = 0;
    model.addListener(() => notified++);
    model.setVoice('fr', 'M2');
    expect(notified, 1);
    expect((await model.voiceFor('fr-CA'))?.id, 'M2');
    expect(await model.voiceFor('zh'), isNull);
  });

  test('saves the chosen voices, ignoring old cloud voices', () {
    model.setVoice('pt_BR', 'M5');
    expect(model.toJson()['neuralVoices'], {'pt-br': 'M5'});

    final restored = TtsModel.fromJson({
      'voice': {'fr': 'fr-FR-Wavenet-A'},
      'neuralVoices': {'ja': 'M3', 'fr': 3},
    }, engine: system);
    expect(restored.toJson().containsKey('voice'), isFalse);
    expect(restored.toJson()['neuralVoices'], {'ja': 'M3'});
  });
}
