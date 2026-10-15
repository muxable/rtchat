import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';

import '../fakes/fake_tts_engine.dart';

final timestamp = DateTime(2024, 1, 2, 3, 4, 5);

TwitchMessageModel createMessage(String message,
    {TwitchUserModel author = const TwitchUserModel(
        userId: '1', login: 'muxfd', displayName: 'Muxfd'),
    bool isAction = false,
    String messageId = 'placeholder',
    List<Emote> thirdPartyEmotes = const []}) {
  return TwitchMessageModel(
      messageId: messageId,
      author: author,
      tags: const {},
      annotations: TwitchMessageAnnotationsModel(
          isAction: isAction, isFirstTimeChatter: false, announcement: null),
      thirdPartyEmotes: thirdPartyEmotes,
      timestamp: timestamp,
      message: message,
      deleted: false,
      channelId: 'placeholder');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  final l10n = lookupAppLocalizations(const Locale('en'));
  late FakeTtsEngine engine;
  late TtsModel model;

  setUp(() {
    engine = FakeTtsEngine();
    model = TtsModel.fromJson({}, engine: engine);
  });

  group('getVocalization of chat messages', () {
    test('returns plain text without a prelude by default', () {
      expect(model.getVocalization(l10n, createMessage('hello world')),
          'hello world');
    });

    test('includes the author prelude when requested', () {
      expect(
          model.getVocalization(l10n, createMessage('hello'),
              includeAuthorPrelude: true),
          l10n.saidMessage('Muxfd', 'hello'));
    });

    test('uses the action prelude for /me messages', () {
      expect(
          model.getVocalization(l10n, createMessage('waves', isAction: true),
              includeAuthorPrelude: true),
          l10n.actionMessage('Muxfd', 'waves'));
    });

    test('falls back to login when there is no display name', () {
      final message = createMessage('hello',
          author: const TwitchUserModel(userId: '1', login: 'muxfd'));
      expect(model.getVocalization(l10n, message, includeAuthorPrelude: true),
          l10n.saidMessage('muxfd', 'hello'));
    });

    test('omits the prelude when prelude is muted', () {
      model.isPreludeMuted = true;
      expect(
          model.getVocalization(l10n, createMessage('hello'),
              includeAuthorPrelude: true),
          'hello');
    });

    test('returns empty for whitespace-only messages', () {
      expect(
          model.getVocalization(l10n, createMessage('   '),
              includeAuthorPrelude: true),
          '');
    });

    test('replaces underscores in mentions with spaces', () {
      expect(model.getVocalization(l10n, createMessage('hi @some_user_name')),
          'hi some user name');
    });

    test('reads only the host of links', () {
      expect(
          model.getVocalization(
              l10n, createMessage('see https://example.com/some/path?q=1')),
          'see example.com');
    });

    group('emotes', () {
      final emotes = [
        Emote(
            provider: 'bttv',
            category: null,
            id: 'kappa',
            code: 'Kappa',
            imageUrl: 'https://example.com/kappa.png'),
      ];

      test('are read by code when not muted', () {
        expect(
            model.getVocalization(
                l10n, createMessage('hi Kappa', thirdPartyEmotes: emotes)),
            'hi Kappa');
      });

      test('are dropped when muted', () {
        model.isEmoteMuted = true;
        expect(
            model.getVocalization(
                l10n, createMessage('hi Kappa', thirdPartyEmotes: emotes)),
            'hi ');
      });

      test('emote-only messages are empty when muted', () {
        model.isEmoteMuted = true;
        expect(
            model.getVocalization(
                l10n, createMessage('Kappa', thirdPartyEmotes: emotes),
                includeAuthorPrelude: true),
            '');
      });
    });
  });

  group('getVocalization of events', () {
    test('stream online and offline', () {
      expect(
          model.getVocalization(
              l10n,
              StreamStateEventModel(
                  messageId: 'a', isOnline: true, timestamp: timestamp)),
          l10n.streamOnline(timestamp, timestamp));
      expect(
          model.getVocalization(
              l10n,
              StreamStateEventModel(
                  messageId: 'a', isOnline: false, timestamp: timestamp)),
          l10n.streamOffline(timestamp, timestamp));
    });

    test('system messages are read verbatim', () {
      expect(
          model.getVocalization(l10n, SystemMessageModel(text: 'tts enabled')),
          'tts enabled');
    });

    test('raid', () {
      expect(
          model.getVocalization(
              l10n,
              TwitchRaidEventModel(
                  messageId: 'a',
                  timestamp: timestamp,
                  from: const TwitchUserModel(
                      userId: '2', login: 'raider', displayName: 'Raider'),
                  viewers: 42)),
          'Raider is raiding with 42 viewers!');
    });

    test('follow uses the first follower, falling back to login', () {
      expect(
          model.getVocalization(
              l10n,
              TwitchFollowEventModel(
                  messageId: 'a',
                  timestamp: timestamp,
                  followers: const [
                    TwitchUserModel(userId: '2', login: 'first'),
                    TwitchUserModel(
                        userId: '3', login: 'second', displayName: 'Second'),
                  ])),
          'first is following you');
    });

    test('subscription tiers are spoken as 1/2/3', () {
      for (final (tier, spoken) in [
        ('1000', '1'),
        ('2000', '2'),
        ('3000', '3')
      ]) {
        expect(
            model.getVocalization(
                l10n,
                TwitchSubscriptionEventModel(
                    messageId: 'a',
                    timestamp: timestamp,
                    subscriberUserName: 'sub',
                    isGift: false,
                    tier: tier)),
            'sub has subscribed at Tier $spoken!');
      }
    });

    test('subscription gift', () {
      expect(
          model.getVocalization(
              l10n,
              TwitchSubscriptionGiftEventModel(
                  messageId: 'a',
                  timestamp: timestamp,
                  gifterUserName: 'gifter',
                  tier: '1000',
                  total: 5,
                  cumulativeTotal: 20)),
          'gifter has gifted 5 Tier 1 subs, totaling 20!');
    });

    test('subscription message', () {
      expect(
          model.getVocalization(
              l10n,
              TwitchSubscriptionMessageEventModel(
                  messageId: 'a',
                  timestamp: timestamp,
                  subscriberUserName: 'sub',
                  tier: '2000',
                  cumulativeMonths: 12,
                  durationMonths: 1,
                  streakMonths: 3,
                  emotes: const [],
                  text: 'hi')),
          'sub has subscribed for 12 months at Tier 2!');
    });

    test('unhandled events are silent', () {
      expect(
          model.getVocalization(
              l10n,
              TwitchCheerEventModel(
                  messageId: 'a',
                  timestamp: timestamp,
                  bits: 100,
                  isAnonymous: false,
                  cheerMessage: 'cheer100',
                  giverName: 'cheerer')),
          '');
      expect(
          model.getVocalization(l10n,
              ChatClearedEventModel(messageId: 'a', timestamp: timestamp)),
          '');
    });
  });

  group('json', () {
    test('defaults', () {
      expect(model.isBotMuted, isFalse);
      expect(model.isEmoteMuted, isFalse);
      expect(model.isPreludeMuted, isFalse);
      expect(model.isRandomVoiceEnabled, isTrue);
      expect(model.pitch, 1.0);
      expect(model.mode, TtsMode.disabled);
    });

    test('round trip', () {
      final json = {
        'isBotMuted': true,
        'isEmoteMuted': true,
        'isPreludeMuted': true,
        'isRandomVoiceEnabled': false,
        'language': 'fr',
        'pitch': 1.5,
        'speed': 0.6,
        'neuralVoices': {'ja': 'M3', 'pt-br': 'F2'},
        'isVoicePackSuggestionDismissed': true,
        'mutedUsers': [
          {
            'provider': 'kick',
            'userId': '1',
            'login': 'muxfd',
            'displayName': 'Muxfd'
          },
        ],
      };
      final roundTripped = TtsModel.fromJson(json, engine: engine).toJson();
      expect(roundTripped, json);
      expect(TtsModel.fromJson(roundTripped, engine: engine).toJson(), json);
    });

    test('muted users saved before providers existed are twitch users', () {
      final restored = TtsModel.fromJson({
        'mutedUsers': [
          {'userId': '1', 'login': 'muxfd', 'displayName': 'Muxfd'},
        ],
      }, engine: engine);
      expect(restored.toJson()['mutedUsers'], [
        {
          'provider': 'twitch',
          'userId': '1',
          'displayName': 'Muxfd',
          'login': 'muxfd'
        },
      ]);
      expect(
          restored.isMuted(const TwitchUserModel(userId: '1', login: 'muxfd')),
          isTrue);
    });

    test('settings saved by versions with cloud tts still load', () {
      final restored = TtsModel.fromJson(engine: engine, {
        'isBotMuted': true,
        'isCloudTtsEnabled': true,
        'isRandomVoiceEnabled': false,
        'language': 'fr',
        'pitch': 1.5,
        'speed': 0.6,
        'voice': {'fr': 'fr-FR-Wavenet-A'},
      });
      expect(restored.isBotMuted, isTrue);
      expect(restored.isRandomVoiceEnabled, isFalse);
      expect(restored.language.languageCode, 'fr');
      expect(restored.pitch, 1.5);
      expect(restored.speed, 0.6);
      final json = restored.toJson();
      // cloud voice names mean nothing to neural voices.
      expect(json.containsKey('voice'), isFalse);
      expect(json['neuralVoices'], isEmpty);
      expect(json.containsKey('isCloudTtsEnabled'), isFalse);
    });

    test('muted users survive a round trip', () {
      const user =
          TwitchUserModel(userId: '1', login: 'muxfd', displayName: 'Muxfd');
      model.mute(user);
      final restored = TtsModel.fromJson(model.toJson(), engine: engine);
      expect(restored.isMuted(user), isTrue);
      restored.unmute(user);
      expect(restored.isMuted(user), isFalse);
    });

    test('reloading saved muted users does not duplicate them', () {
      const user =
          TwitchUserModel(userId: '1', login: 'muxfd', displayName: 'Muxfd');
      model.mute(user);
      final json = model.toJson();
      model.updateFromJson(json);
      model.updateFromJson(json);
      expect(model.toJson()['mutedUsers'], json['mutedUsers']);
    });

    test('reloading saved muted users drops users unmuted elsewhere', () {
      const user =
          TwitchUserModel(userId: '1', login: 'muxfd', displayName: 'Muxfd');
      model.mute(user);
      model.updateFromJson({'mutedUsers': []});
      expect(model.isMuted(user), isFalse);
    });

    test('muting matches on login', () {
      model.mute(const TwitchUserModel(userId: '1', login: 'nodisplayname'));
      expect(model.isMuted(const TwitchUserModel(userId: '2', login: 'other')),
          isFalse);
      expect(
          model.isMuted(const TwitchUserModel(
              userId: '1', login: 'NoDisplayName', displayName: 'Renamed')),
          isTrue);
      model.unmute(const TwitchUserModel(userId: '1', login: 'nodisplayname'));
      expect(
          model.isMuted(
              const TwitchUserModel(userId: '1', login: 'nodisplayname')),
          isFalse);
    });
  });

  group('utterance queue', () {
    test('speaks messages in order', () async {
      model.setMode(l10n, TtsMode.enabled);
      model.say(l10n, createMessage('first', messageId: 'first'));
      model.say(l10n, createMessage('second', messageId: 'second'));
      await pumpEventQueue();

      expect(engine.spoken, [
        'Text to speech enabled',
        'Muxfd said: first',
        'Muxfd said: second',
      ]);
    });

    test('waits for each utterance to finish before the next', () async {
      engine.holdSpeech = true;
      model.setMode(l10n, TtsMode.enabled);
      model.say(l10n, createMessage('first', messageId: 'first'));
      await pumpEventQueue();
      expect(engine.spoken, ['Text to speech enabled']);

      engine.finishSpeaking();
      await pumpEventQueue();
      expect(engine.spoken, ['Text to speech enabled', 'Muxfd said: first']);
    });

    test('drops the author prelude for consecutive messages by one chatter',
        () async {
      engine.holdSpeech = true;
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      engine.finishSpeaking();
      model.say(l10n, createMessage('first', messageId: 'first'));
      await pumpEventQueue();
      model.say(l10n, createMessage('second', messageId: 'second'));
      for (var i = 0; i < 3; i++) {
        engine.finishSpeaking();
        await pumpEventQueue();
      }

      expect(engine.spoken.skip(1), ['Muxfd said: first', 'second']);
    });

    test('speaks with the rate and pitch from the settings', () async {
      model.speed = 0.3;
      model.pitch = 1.7;
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();

      final utterance = engine.utterances.single;
      expect(utterance.rate, 0.3);
      expect(utterance.pitch, 1.7);
      expect(utterance.voice, isNull);
    });

    test('unsaid messages are skipped', () async {
      engine.holdSpeech = true;
      model.setMode(l10n, TtsMode.enabled);
      model.say(l10n, createMessage('first', messageId: 'first'));
      model.say(l10n, createMessage('second', messageId: 'second'));
      await pumpEventQueue();
      model.unsay('first');
      for (var i = 0; i < 3; i++) {
        engine.finishSpeaking();
        await pumpEventQueue();
      }

      expect(engine.spoken, ['Text to speech enabled', 'Muxfd said: second']);
    });

    test('a failed utterance does not block the ones after it', () async {
      // the engine fails the first utterance, and reporting the error fails
      // too (no firebase app in tests).
      await runZonedGuarded(() async {
        model.setMode(l10n, TtsMode.enabled);
        await pumpEventQueue();
        engine.failNext = Exception('tts failed');
        model.say(l10n, createMessage('first', messageId: 'first'));
        await pumpEventQueue();
      }, (error, stack) {});

      await runZonedGuarded(() async {
        model.say(l10n, createMessage('second', messageId: 'second'));
        await pumpEventQueue();
      }, (error, stack) {});

      expect(engine.spoken, isNot(contains('Muxfd said: first')));
      expect(engine.spoken, contains('Muxfd said: second'));
    });

    test('disposing the model disposes the engine', () {
      model.dispose();
      expect(engine.isDisposed, isTrue);
    });
  });

  group('backlog', () {
    // speech never finishes on its own, so messages pile up like they do
    // when chat outpaces tts. stopping tts ends the current utterance.
    setUp(() => engine.holdSpeech = true);
    tearDown(() => engine.finishSpeaking());

    TwitchMessageModel from(int i) => createMessage('message $i',
        messageId: 'm$i',
        author: TwitchUserModel(
            userId: '$i', login: 'user$i', displayName: 'User$i'));

    test('turns tts off and says so when too many messages are queued',
        () async {
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      for (var i = 0; i < 25; i++) {
        model.say(l10n, from(i));
      }
      await pumpEventQueue();

      expect(model.mode, TtsMode.disabled);
      expect(engine.stopCount, 1);
      expect(engine.spoken.last, l10n.textToSpeechTooManyMessages);
      expect(engine.spoken.where((s) => s.contains(' said: ')), isEmpty);
    });

    test('skips the author prelude to catch up on a long backlog', () async {
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      for (var i = 0; i < 12; i++) {
        model.say(l10n, from(i));
      }
      // let the backlog drain.
      for (var i = 0; i < 20; i++) {
        engine.finishSpeaking();
        await pumpEventQueue();
      }

      expect(engine.spoken, contains('User1 said: message 1'));
      expect(engine.spoken, contains('message 11'));
      expect(model.mode, TtsMode.enabled);
      expect(engine.stopCount, 0);
    });
  });
}
