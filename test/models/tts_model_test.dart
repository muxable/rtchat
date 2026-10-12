import 'package:flutter/services.dart';
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

final timestamp = DateTime(2024, 1, 2, 3, 4, 5);

TwitchMessageModel createMessage(String message,
    {TwitchUserModel author = const TwitchUserModel(
        userId: '1', login: 'muxfd', displayName: 'Muxfd'),
    bool isAction = false,
    List<Emote> thirdPartyEmotes = const []}) {
  return TwitchMessageModel(
      messageId: 'placeholder',
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

  // TtsModel eagerly creates platform-backed players; stub them out.
  setUpAll(() async {
    await initializeDateFormatting('en');
    for (final name in ['flutter_tts', 'com.ryanheise.just_audio.methods']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
  });

  final l10n = lookupAppLocalizations(const Locale('en'));
  late TtsModel model;

  setUp(() {
    model = TtsModel.fromJson({});
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
          l10n.raidEventMessage('Raider', 42));
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
          l10n.followingEvent('first'));
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
            l10n.subscriptionEvent('sub', spoken));
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
          l10n.subscriptionGiftEvent('gifter', 5, '1', 20));
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
          l10n.subscriptionMessageEvent('sub', 12, '2'));
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
        'voice': {'fr': 'fr-FR-Wavenet-A'},
        'mutedUsers': [
          {'userId': '1', 'login': 'muxfd', 'displayName': 'Muxfd'},
        ],
      };
      final roundTripped = TtsModel.fromJson(json).toJson();
      expect(roundTripped, json);
      expect(TtsModel.fromJson(roundTripped).toJson(), json);
    });

    test('muted users survive a round trip', () {
      const user =
          TwitchUserModel(userId: '1', login: 'muxfd', displayName: 'Muxfd');
      model.mute(user);
      final restored = TtsModel.fromJson(model.toJson());
      expect(restored.isMuted(user), isTrue);
      restored.unmute(user);
      expect(restored.isMuted(user), isFalse);
    });
  });
}
