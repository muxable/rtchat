import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';
import 'package:rtchat/models/tts.dart';

final t0 = DateTime(2026);
const viewer = YouTubeUserModel(userId: 'UCviewer', displayName: '@Viewer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    for (final name in ['flutter_tts', 'com.ryanheise.just_audio.methods']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
  });

  final l10n = lookupAppLocalizations(const Locale('en'));
  late TtsModel model;

  setUp(() {
    model = TtsModel.fromJson({});
    addTearDown(model.dispose);
  });

  String say(MessageModel message, {bool includeAuthorPrelude = false}) =>
      model.getVocalization(l10n, message,
          includeAuthorPrelude: includeAuthorPrelude);

  test('localizes unknown and known jewel amounts in every locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final localized = lookupAppLocalizations(locale);
      final unknown =
          localized.youtubeGiftEvent('Viewer', 'Rose', 0, 'unknown');
      expect(unknown, contains('Rose'), reason: '$locale');
      expect(unknown, isNot(contains('Jewels')), reason: '$locale');
      expect(localized.youtubeGiftEvent('Viewer', 'Rose', 0, 'known'),
          contains('Jewels'),
          reason: '$locale');
    }
  });

  test('reads youtube chat with its author', () {
    final message = YouTubeMessageModel(
        messageId: 'youtube:m',
        timestamp: t0,
        author: viewer,
        message: 'hello https://youtube.com/watch',
        channelId: 'youtube:UCstreamer');
    expect(say(message), 'hello youtube.com');
    expect(say(message, includeAuthorPrelude: true),
        '@Viewer said: hello youtube.com');
  });

  test('announces super chats and stickers without markup', () {
    expect(
        say(YouTubeSuperChatEventModel(
            messageId: 'youtube:sc',
            timestamp: t0,
            author: viewer,
            amountMicros: 5000000,
            currency: 'USD',
            amountDisplayString: '\$5.00',
            tier: 3,
            comment: 'great stream!')),
        '@Viewer sent a \$5.00 Super Chat! great stream!');
    expect(
        say(YouTubeSuperChatEventModel(
            messageId: 'youtube:sc',
            timestamp: t0,
            author: viewer,
            amountMicros: 5000000,
            currency: 'USD',
            amountDisplayString: '\$5.00',
            tier: 3)),
        '@Viewer sent a \$5.00 Super Chat!');
    expect(
        say(YouTubeSuperStickerEventModel(
            messageId: 'youtube:ss',
            timestamp: t0,
            author: viewer,
            amountMicros: 2000000,
            currency: 'USD',
            amountDisplayString: '\$2.00',
            tier: 2,
            stickerId: 's')),
        '@Viewer sent a \$2.00 Super Sticker!');
  });

  test('announces memberships', () {
    expect(
        say(YouTubeNewMemberEventModel(
            messageId: 'youtube:n',
            timestamp: t0,
            member: viewer,
            levelName: 'Super Fan',
            isUpgrade: false)),
        '@Viewer became a member!');
    expect(
        say(YouTubeNewMemberEventModel(
            messageId: 'youtube:u',
            timestamp: t0,
            member: viewer,
            levelName: 'Mega Fan',
            isUpgrade: true)),
        '@Viewer upgraded to Mega Fan!');
    expect(
        say(YouTubeMemberMilestoneEventModel(
            messageId: 'youtube:ms',
            timestamp: t0,
            member: viewer,
            levelName: 'Super Fan',
            months: 6,
            comment: 'yay')),
        '@Viewer has been a member for 6 months! yay');
    expect(
        say(YouTubeMembershipGiftingEventModel(
            messageId: 'youtube:g',
            timestamp: t0,
            gifter: viewer,
            count: 1,
            levelName: '')),
        '@Viewer gifted a membership!');
    expect(
        say(YouTubeMembershipGiftingEventModel(
            messageId: 'youtube:g',
            timestamp: t0,
            gifter: viewer,
            count: 10,
            levelName: '')),
        '@Viewer gifted 10 memberships!');
    expect(
        say(YouTubeGiftMembershipReceivedEventModel(
            messageId: 'youtube:r',
            timestamp: t0,
            recipient: viewer,
            levelName: '')),
        '@Viewer received a gifted membership!');
  });

  test('announces gifts, polls and chat state', () {
    expect(
        say(YouTubeGiftEventModel(
            messageId: 'youtube:gift',
            timestamp: t0,
            sender: viewer,
            giftName: 'Rose',
            jewels: 10)),
        '@Viewer sent Rose (10 Jewels)!');
    expect(
        say(YouTubeGiftEventModel(
            messageId: 'youtube:gift-unknown',
            timestamp: t0,
            sender: viewer,
            giftName: 'Rose')),
        '@Viewer sent Rose!');

    YouTubePollEventModel poll(bool isClosed) => YouTubePollEventModel(
        messageId: 'youtube:p',
        timestamp: t0,
        author: viewer,
        question: 'Best snack?',
        options: const [],
        isClosed: isClosed);
    expect(say(poll(false)), 'Poll: Best snack?');
    expect(say(poll(true)), '');
    expect(
        say(YouTubeMembersOnlyModeEventModel(
            messageId: 'youtube:on', timestamp: t0, isEnabled: true)),
        'Members-only mode is on');
    expect(
        say(YouTubeMembersOnlyModeEventModel(
            messageId: 'youtube:off', timestamp: t0, isEnabled: false)),
        'Members-only mode is off');
    expect(
        say(YouTubeChatEndedEventModel(messageId: 'youtube:e', timestamp: t0)),
        'The live chat has ended');
  });
}
