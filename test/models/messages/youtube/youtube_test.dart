import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/parse.dart';

final channel = Channel(Providers.youtube, 'UCstreamer', 'Streamer');
final publishedAt = DateTime.utc(2026, 10, 14, 12);

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/youtube/$name.json').readAsStringSync());

T append<T>(String name) => appendJson<T>(fixture(name));

T appendJson<T>(Map<String, dynamic> message) {
  final event = youTubeDeltaEvent(message, channel: channel);
  expect(event, isA<AppendDeltaEvent>());
  final model = (event as AppendDeltaEvent).model;
  expect(model.channel, channel);
  return model as T;
}

/// [fixture] with the type's details replaced by [details].
Map<String, dynamic> withDetails(
    String name, String key, Map<String, dynamic> details) {
  final message = fixture(name);
  message['snippet'][key] = details;
  return message;
}

void main() {
  group('text messages', () {
    test('parses the author and message', () {
      final message = append<YouTubeMessageModel>('textMessageEvent');
      expect(message.messageId, 'youtube:LCC.text');
      expect(message.timestamp, publishedAt);
      expect(message.channelId, 'youtube:UCstreamer');
      expect(message.message, 'hi @someone see https://youtube.com :wave:');
      expect(message.author.userId, 'UCauthor');
      expect(message.author.displayName, '@Viewer');
      expect(message.author.login, '@viewer');
      expect(message.author.provider, 'youtube');
      expect(
          message.author.profileImageUrl, 'https://yt3.ggpht.com/viewer.jpg');
      expect(message.author.isChatModerator, isTrue);
      expect(message.author.isChatSponsor, isTrue);
      expect(message.author.isChatOwner, isFalse);
      expect(message.author.isVerified, isFalse);
      expect(message.isSubscriber, isTrue);
      expect(message.deleted, isFalse);
    });

    test('tokenizes mentions and links and leaves emoji as text', () {
      final message = append<YouTubeMessageModel>('textMessageEvent');
      expect(message.tokenized.whereType<UserMentionToken>().single.username,
          'someone');
      expect(message.tokenized.whereType<LinkToken>().single.url.host,
          'youtube.com');
      expect(message.tokenized.last, const TextToken(' :wave:'));
    });

    test('tolerates missing author details and text', () {
      final message = appendJson<YouTubeMessageModel>({
        'id': 'm',
        'snippet': {'type': 'textMessageEvent'},
      });
      expect(message.message, '');
      expect(message.author.userId, '');
      expect(message.author.displayName, isNull);
      expect(message.isCommand, isFalse);
    });

    test('falls back to the display message', () {
      final message = appendJson<YouTubeMessageModel>({
        'id': 'm',
        'snippet': {'type': 'textMessageEvent', 'displayMessage': '!discord'},
      });
      expect(message.message, '!discord');
      expect(message.isCommand, isTrue);
    });
  });

  group('paid messages', () {
    test('super chats', () {
      final superChat = append<YouTubeSuperChatEventModel>('superChatEvent');
      expect(superChat.messageId, 'youtube:LCC.superchat');
      expect(superChat.amountMicros, 5000000);
      expect(superChat.currency, 'USD');
      expect(superChat.amountDisplayString, '\$5.00');
      expect(superChat.comment, 'great stream!');
      expect(superChat.tier, 3);
      expect(superChat.author.displayName, '@Viewer');
    });

    test('super chats with numbers as numbers and no comment', () {
      final superChat = appendJson<YouTubeSuperChatEventModel>(
          withDetails('superChatEvent', 'superChatDetails', {
        'amountMicros': 2000000,
        'currency': 'EUR',
        'amountDisplayString': '€2.00',
        'tier': '2',
      }));
      expect(superChat.amountMicros, 2000000);
      expect(superChat.tier, 2);
      expect(superChat.comment, isNull);
    });

    test('super chats without details', () {
      final superChat = appendJson<YouTubeSuperChatEventModel>(
          withDetails('superChatEvent', 'superChatDetails', {}));
      expect(superChat.amountMicros, 0);
      expect(superChat.tier, 1);
      expect(superChat.amountDisplayString, '');
    });

    test('super stickers', () {
      final sticker =
          append<YouTubeSuperStickerEventModel>('superStickerEvent');
      expect(sticker.amountMicros, 20000000);
      expect(sticker.amountDisplayString, '\$20.00');
      expect(sticker.tier, 5);
      expect(sticker.stickerId, 'sticker_1');
      expect(sticker.altText, 'Dancing cat');
    });

    test('super stickers without metadata', () {
      final sticker = appendJson<YouTubeSuperStickerEventModel>(
          withDetails('superStickerEvent', 'superStickerDetails', {
        'amountMicros': '1000000',
        'tier': 1,
      }));
      expect(sticker.stickerId, '');
      expect(sticker.altText, isNull);
      expect(sticker.amountMicros, 1000000);
    });
  });

  group('memberships', () {
    test('new members and upgrades', () {
      final member = append<YouTubeNewMemberEventModel>('newSponsorEvent');
      expect(member.levelName, 'Super Fan');
      expect(member.isUpgrade, isFalse);
      expect(member.member.userId, 'UCauthor');
      final upgrade =
          append<YouTubeNewMemberEventModel>('newSponsorEvent.upgrade');
      expect(upgrade.levelName, 'Mega Fan');
      expect(upgrade.isUpgrade, isTrue);
    });

    test('new members without details', () {
      final member = appendJson<YouTubeNewMemberEventModel>({
        'id': 'm',
        'snippet': {'type': 'newSponsorEvent'},
        'authorDetails': {'channelId': 'UC1', 'displayName': 'A'},
      });
      expect(member.levelName, '');
      expect(member.isUpgrade, isFalse);
    });

    test('milestones with string months', () {
      final milestone =
          append<YouTubeMemberMilestoneEventModel>('memberMilestoneChatEvent');
      expect(milestone.months, 6);
      expect(milestone.levelName, 'Super Fan');
      expect(milestone.comment, 'half a year!');
    });

    test('milestones without a comment', () {
      final milestone = appendJson<YouTubeMemberMilestoneEventModel>(
          withDetails('memberMilestoneChatEvent', 'memberMilestoneChatDetails',
              {'memberMonth': 12, 'userComment': ''}));
      expect(milestone.months, 12);
      expect(milestone.comment, isNull);
    });

    test('gifted memberships', () {
      final gifting =
          append<YouTubeMembershipGiftingEventModel>('membershipGiftingEvent');
      expect(gifting.count, 5);
      expect(gifting.levelName, 'Super Fan');
      expect(gifting.gifter.displayName, '@Viewer');
      final stringCount = appendJson<YouTubeMembershipGiftingEventModel>(
          withDetails('membershipGiftingEvent', 'membershipGiftingDetails',
              {'giftMembershipsCount': '20'}));
      expect(stringCount.count, 20);
      expect(stringCount.levelName, '');
    });

    test('received gift memberships', () {
      final received = append<YouTubeGiftMembershipReceivedEventModel>(
          'giftMembershipReceivedEvent');
      expect(received.levelName, 'Super Fan');
      expect(received.gifterChannelId, 'UCgifter');
      expect(received.recipient.userId, 'UCauthor');
    });
  });

  group('other events', () {
    test('jewels gifts', () {
      final gift = append<YouTubeGiftEventModel>('giftEvent');
      expect(gift.giftName, 'Rose');
      expect(gift.jewels, 10);
      expect(gift.comboCount, 3);
      expect(gift.giftUrl, 'https://www.gstatic.com/rose.png');
      expect(gift.altText, 'A rose');
      final bare = appendJson<YouTubeGiftEventModel>(
          withDetails('giftEvent', 'giftDetails', {'giftName': 'Heart'}));
      expect(bare.jewels, isNull);
      expect(bare.comboCount, 1);
      expect(bare.giftUrl, isNull);
      final zero = appendJson<YouTubeGiftEventModel>(withDetails('giftEvent',
          'giftDetails', {'giftName': 'Heart', 'jewelsAmount': 0}));
      expect(zero.jewels, 0);
    });

    test('polls', () {
      final poll = append<YouTubePollEventModel>('pollEvent');
      expect(poll.question, 'Best snack?');
      expect(poll.options.map((o) => o.text), ['Chips', 'Popcorn']);
      expect(poll.options.map((o) => o.tally), [12, 30]);
      expect(poll.totalVotes, 42);
      expect(poll.maxVotes, 30);
      expect(poll.isClosed, isFalse);
      final closed = appendJson<YouTubePollEventModel>(
          withDetails('pollEvent', 'pollDetails', {'status': 'closed'}));
      expect(closed.isClosed, isTrue);
      expect(closed.options, isEmpty);
      expect(closed.question, '');
    });

    test('members-only mode', () {
      expect(
          append<YouTubeMembersOnlyModeEventModel>(
                  'sponsorOnlyModeStartedEvent')
              .isEnabled,
          isTrue);
      expect(
          append<YouTubeMembersOnlyModeEventModel>('sponsorOnlyModeEndedEvent')
              .isEnabled,
          isFalse);
    });

    test('chat ended', () {
      final ended = append<YouTubeChatEndedEventModel>('chatEndedEvent');
      expect(ended.messageId, 'youtube:LCC.end');
    });

    test('ignores unknown types', () {
      expect(
          youTubeDeltaEvent({
            'id': 'x',
            'snippet': {'type': 'somethingNewEvent'}
          }, channel: channel),
          isNull);
      expect(youTubeDeltaEvent({}, channel: channel), isNull);
    });

    test('a missing timestamp is now', () {
      final before = DateTime.now();
      final ended = appendJson<YouTubeChatEndedEventModel>({
        'id': 'e',
        'snippet': {'type': 'chatEndedEvent'}
      });
      expect(ended.timestamp.isBefore(before), isFalse);
    });
  });

  group('deletions', () {
    test('a tombstone marks its message deleted', () {
      final chat = append<YouTubeMessageModel>('textMessageEvent');
      final other = appendJson<YouTubeMessageModel>({
        ...fixture('textMessageEvent'),
        'id': 'LCC.other',
      });
      final event = youTubeDeltaEvent(fixture('tombstone'), channel: channel);
      expect(event, isA<UpdateDeltaEvent>());
      expect((event as UpdateDeltaEvent).messageId, 'youtube:LCC.text');
      final messages = applyDeltaEvent([chat, other], event);
      expect((messages[0] as YouTubeMessageModel).deleted, isTrue);
      expect((messages[1] as YouTubeMessageModel).deleted, isFalse);
    });

    test('a message deleted event marks its message deleted', () {
      final chat = append<YouTubeMessageModel>('textMessageEvent');
      final event = youTubeDeltaEvent({
        'id': 'LCC.deletion',
        'snippet': {
          'type': 'messageDeletedEvent',
          'messageDeletedDetails': {'deletedMessageId': 'LCC.text'},
        },
      }, channel: channel);
      final messages = applyDeltaEvent([chat], event!);
      expect((messages.single as YouTubeMessageModel).deleted, isTrue);
    });

    test('a ban removes the banned user\'s messages', () {
      final chat = append<YouTubeMessageModel>('textMessageEvent');
      final other = appendJson<YouTubeMessageModel>({
        ...fixture('textMessageEvent'),
        'id': 'LCC.other',
        'authorDetails': {'channelId': 'UCother', 'displayName': 'Other'},
      });
      final superChat = append<YouTubeSuperChatEventModel>('superChatEvent');
      final event =
          youTubeDeltaEvent(fixture('userBannedEvent'), channel: channel);
      expect(event, isA<UpdateAllDeltaEvent>());
      final messages =
          applyDeltaEvent(<MessageModel>[chat, other, superChat], event!);
      expect((messages[0] as YouTubeMessageModel).deleted, isTrue);
      expect((messages[1] as YouTubeMessageModel).deleted, isFalse);
      expect(messages[2], same(superChat));
    });

    test('a ban without a user is ignored', () {
      expect(
          youTubeDeltaEvent({
            'id': 'b',
            'snippet': {'type': 'userBannedEvent'}
          }, channel: channel),
          isNull);
    });
  });
}
