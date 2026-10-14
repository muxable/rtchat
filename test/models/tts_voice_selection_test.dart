import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

import '../fakes/fake_tts_engine.dart';

/// The languages of Supertonic 3.
const supertonicLanguages = [
  'en', 'ko', 'ja', 'ar', 'bg', 'cs', 'da', 'de', 'el', 'es', 'et', //
  'fi', 'fr', 'hi', 'hr', 'hu', 'id', 'it', 'lt', 'lv', 'nl', 'pl', 'pt',
  'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'vi',
];

var _messages = 0;

TwitchMessageModel chat(String text,
        {String userId = '1', String login = 'user1', Channel? channel}) =>
    TwitchMessageModel(
        messageId: 'm${_messages++}',
        author: TwitchUserModel(
            userId: userId, login: login, displayName: 'User$userId'),
        tags: const {},
        annotations: const TwitchMessageAnnotationsModel(
            isAction: false, isFirstTimeChatter: false, announcement: null),
        thirdPartyEmotes: const [],
        timestamp: DateTime(2024),
        message: text,
        deleted: false,
        channelId: 'placeholder')
      ..channel = channel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  final l10n = lookupAppLocalizations(const Locale('en'));
  final japanese = Channel(Providers.twitch, 'jp', 'jp');
  final chinese = Channel(Providers.twitch, 'zh', 'zh');
  final brazilian = Channel(Providers.kick, 'br', 'br');

  late FakeTtsEngine system;
  late FakeTtsEngine neural;
  late List<Object> errors;
  late TtsModel model;

  TtsModel createModel(Map<String, dynamic> json) {
    final model = TtsModel.fromJson(json,
        engine: system, reportError: (error, _) => errors.add(error));
    model.neuralEngine = neural;
    model.setChannelLanguage(japanese, Language('ja'));
    model.setChannelLanguage(chinese, Language('zh'));
    model.setChannelLanguage(brazilian, Language('pt-BR'));
    // TtsMode.enabled without the "enabled" announcement.
    model.setMode(l10n, TtsMode.enabled);
    return model;
  }

  setUp(() async {
    system = FakeTtsEngine();
    neural = FakeTtsEngine(availableVoices: packVoices(supertonicLanguages));
    errors = [];
    model = createModel({'language': 'en'});
    await pumpEventQueue();
    neural.utterances.clear();
  });

  tearDown(() => expect(errors, isEmpty));

  group('language routing', () {
    test('a Japanese channel is read by the neural engine in Japanese',
        () async {
      model.say(l10n, chat('konnichiwa', channel: japanese));
      await pumpEventQueue();

      expect(neural.utterances.single.text, 'User1 said: konnichiwa');
      expect(neural.utterances.single.language, 'ja');
      expect(system.utterances, isEmpty);
    });

    test('a language no pack speaks is read by the system voice in it',
        () async {
      model.say(l10n, chat('ni hao', channel: chinese));
      model.say(l10n, chat('hello', userId: '2'));
      await pumpEventQueue();

      expect(system.utterances.single.text, 'User1 said: ni hao');
      expect(system.utterances.single.language, 'zh');
      // The neural engine stays for the next message in a language it has.
      expect(neural.utterances.single.text, 'User2 said: hello');
      expect(neural.utterances.single.language, 'en');
    });

    test('a region falls back to the language the pack has', () async {
      model.say(l10n, chat('oi', channel: brazilian));
      await pumpEventQueue();

      expect(neural.utterances.single.language, 'pt');
    });

    test('without a channel language the TTS language is used', () async {
      model.language = Language('es');
      model.say(l10n, chat('hola'));
      await pumpEventQueue();

      expect(neural.utterances.single.language, 'es');
    });

    test(
        'the system voice keeps its own language when the channel language is '
        'unknown', () async {
      model.language = Language('zh');
      model.say(l10n, chat('ni hao'));
      await pumpEventQueue();

      expect(system.utterances.single.text, 'User1 said: ni hao');
      expect(system.utterances.single.language, isNull);
    });

    test('everything goes to the system voice without a neural engine',
        () async {
      model.neuralEngine = null;
      model.say(l10n, chat('konnichiwa', channel: japanese));
      model.say(l10n, chat('hello', userId: '2'));
      await pumpEventQueue();

      expect(neural.utterances, isEmpty);
      expect(system.utterances.map((u) => u.language), ['ja', null]);
    });

    test('a neural error falls back to the system voice for that message',
        () async {
      neural.failNext = PlatformException(code: 'speak_failed');
      model.say(l10n, chat('konnichiwa', channel: japanese));
      model.say(l10n, chat('sayonara', userId: '2', channel: japanese));
      await pumpEventQueue();

      expect(system.utterances.single.text, 'User1 said: konnichiwa');
      expect(system.utterances.single.language, 'ja');
      expect(neural.spoken, ['User2 said: sayonara']);
      expect(errors.single, isA<PlatformException>());
      errors.clear();
    });

    test('packs are tried in order of preference', () async {
      final english = FakeTtsEngine(
          availableVoices: packVoices(['en-US', 'en-GB'], speakers: ['af']));
      model.neuralEngines = [english, neural];
      model.say(l10n, chat('hello'));
      model.say(l10n, chat('konnichiwa', channel: japanese));
      await pumpEventQueue();

      expect(english.utterances.single.language, 'en-US');
      expect(english.utterances.single.voice?.id, 'af');
      expect(neural.utterances.single.language, 'ja');
    });

    test('engines kept across a change are not disposed', () async {
      final other = FakeTtsEngine(availableVoices: packVoices(['en']));
      model.neuralEngines = [other, neural];
      model.neuralEngines = [neural];
      await pumpEventQueue();

      expect(other.isDisposed, isTrue);
      expect(neural.isDisposed, isFalse);
    });
  });

  group('random voice per chatter', () {
    test('a chatter always gets the same voice', () async {
      for (var i = 0; i < 3; i++) {
        model.say(l10n, chat('message $i', userId: '42'));
        model.say(l10n, chat('message $i', userId: '42', channel: japanese));
      }
      await pumpEventQueue();

      final voices = neural.utterances.map((u) => u.voice?.id).toSet();
      expect(voices, hasLength(1));
      // fnv1a32('twitch:42') is 0x03bea9fa, which is 2 mod 10: F3, here
      // and on every other device.
      expect(voices.single, 'F3');
      expect(fnv1a32('twitch:42') % supertonicSpeakers.length, 2);
    });

    test('a chatter keeps their voice in a new model, as after a restart',
        () async {
      model.say(l10n, chat('hello', userId: '7'));
      await pumpEventQueue();
      final voice = neural.utterances.single.voice;

      final restarted =
          FakeTtsEngine(availableVoices: packVoices(supertonicLanguages));
      final again = TtsModel.fromJson(model.toJson(), engine: system)
        ..neuralEngine = restarted
        ..setMode(l10n, TtsMode.enabled);
      again.say(l10n, chat('hello again', userId: '7'));
      await pumpEventQueue();

      expect(restarted.utterances.last.voice, voice);
    });

    test('different chatters spread across the voices', () async {
      // one at a time, so the backlog cutoff stays out of it.
      for (var i = 0; i < 50; i++) {
        model.say(l10n, chat('hi', userId: '$i', login: 'user$i'));
        await pumpEventQueue();
      }
      expect(neural.utterances, hasLength(50));

      final voices = neural.utterances.map((u) => u.voice?.id).toSet();
      expect(voices.length, greaterThanOrEqualTo(8));
    });

    test('chatters are told apart by provider and user id, else login', () {
      expect(TtsModel.voiceKey(const TwitchUserModel(userId: '1', login: 'a')),
          'twitch:1');
      expect(TtsModel.voiceKey(const TwitchUserModel(userId: '', login: 'Ab')),
          'twitch:login:ab');
    });

    test('alerts and system messages get the chosen voice, not a hash',
        () async {
      model.setVoice('en', 'M4');
      model.say(l10n, SystemMessageModel(text: 'hello'));
      model.say(
          l10n,
          TwitchRaidEventModel(
              messageId: 'raid',
              timestamp: DateTime.now(),
              from: const TwitchUserModel(
                  userId: '2', login: 'raider', displayName: 'Raider'),
              viewers: 42)
            ..channel = japanese);
      await pumpEventQueue();

      // In the app's language, as their text is in it.
      expect(neural.utterances.map((u) => (u.voice?.id, u.language)),
          [('M4', 'en'), ('M4', 'en')]);
    });
  });

  group('chosen voice', () {
    setUp(() async {
      model.isRandomVoiceEnabled = false;
    });

    test('defaults to the first voice', () async {
      model.say(l10n, chat('hello', userId: '1'));
      model.say(l10n, chat('hi', userId: '2'));
      await pumpEventQueue();

      expect(neural.utterances.map((u) => u.voice?.id), ['F1', 'F1']);
    });

    test('is the voice picked for the language', () async {
      model.setVoice('ja', 'M3');
      model.setVoice('pt', 'F2');
      model.say(l10n, chat('hello', userId: '1'));
      model.say(l10n, chat('konnichiwa', userId: '2', channel: japanese));
      model.say(l10n, chat('oi', userId: '3', channel: brazilian));
      await pumpEventQueue();

      expect(neural.utterances.map((u) => u.voice?.id), ['F1', 'M3', 'F2']);
    });

    test('a voice picked for a region wins over its language', () async {
      model.setVoice('pt', 'F2');
      model.setVoice('pt-BR', 'M5');
      model.say(l10n, chat('oi', channel: brazilian));
      await pumpEventQueue();

      expect(neural.utterances.single.voice?.id, 'M5');
    });

    test('a voice the pack no longer has falls back to the first', () async {
      model.setVoice('en', 'gone');
      model.say(l10n, chat('hello'));
      await pumpEventQueue();

      expect(neural.utterances.single.voice?.id, 'F1');
    });

    test('is saved with the settings', () async {
      model.setVoice('ja', 'M3');
      final restored = createModel(model.toJson())
        ..isRandomVoiceEnabled = false;
      await pumpEventQueue();
      neural.utterances.clear();
      restored.say(l10n, chat('konnichiwa', channel: japanese));
      await pumpEventQueue();

      expect(neural.utterances.single.voice?.id, 'M3');
    });
  });

  group('voice API', () {
    test('lists the voices for a language', () async {
      expect((await model.availableVoices('ja')).map((v) => v.id),
          supertonicSpeakers);
      expect((await model.availableVoices('pt-BR')).map((v) => v.locale),
          everyElement('pt'));
      expect(await model.availableVoices('zh'), isEmpty);
    });

    test('voiceFor is the chosen voice, else the first', () async {
      expect((await model.voiceFor('fr'))?.id, 'F1');
      model.setVoice('fr', 'M2');
      expect((await model.voiceFor('fr'))?.id, 'M2');
      expect((await model.voiceFor('fr-CA'))?.id, 'M2');
      expect(await model.voiceFor('zh'), isNull);
    });

    test('setVoice notifies listeners', () {
      var notified = 0;
      model.addListener(() => notified++);
      model.setVoice('fr', 'M2');
      expect(notified, 1);
    });
  });

  group('json', () {
    test('saves the chosen voices by normalized language', () {
      model.setVoice('pt_BR', 'M5');
      model.setVoice('ja', 'M3');
      expect(model.toJson()['neuralVoices'], {'pt-br': 'M5', 'ja': 'M3'});
    });

    test('ignores the cloud voices of old settings', () async {
      final restored = TtsModel.fromJson({
        'isRandomVoiceEnabled': false,
        'language': 'fr',
        'voice': {'fr': 'fr-FR-Wavenet-A'},
      }, engine: system)
        ..neuralEngine = neural;
      expect(restored.toJson().containsKey('voice'), isFalse);
      expect(restored.toJson()['neuralVoices'], isEmpty);
      expect((await restored.voiceFor('fr'))?.id, 'F1');
    });

    test('skips malformed entries', () {
      final restored = TtsModel.fromJson({
        'neuralVoices': {'ja': 'M3', 'fr': 3, 'de': null},
      }, engine: system);
      expect(restored.toJson()['neuralVoices'], {'ja': 'M3'});
    });

    test('reloading replaces the chosen voices', () {
      model.setVoice('ja', 'M3');
      model.updateFromJson({
        'neuralVoices': {'fr': 'M2'},
      });
      expect(model.toJson()['neuralVoices'], {'fr': 'M2'});
    });
  });
}
