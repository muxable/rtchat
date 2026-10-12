import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/tokens.dart';

final timestamp = DateTime(2025, 1, 14, 16, 8, 6);

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/kick/$name.json').readAsStringSync());

Map<String, dynamic> doc(String type, Map<String, dynamic> event) => {
      'type': 'kick.$type',
      'channelId': 'kick:123456789',
      'timestamp': Timestamp.fromDate(timestamp),
      'event': event,
    };

T append<T>(String type, [String? fixtureName]) {
  final event = toDeltaEvent(
      const [], 'kick:id', doc(type, fixture(fixtureName ?? type)));
  expect(event, isA<AppendDeltaEvent>());
  return (event as AppendDeltaEvent).model as T;
}

void main() {
  group('chat messages', () {
    test('parses the documented payload', () {
      final message = append<KickMessageModel>('chat.message.sent');
      expect(message.messageId, 'kick:id');
      expect(message.timestamp, timestamp);
      expect(message.channelId, 'kick:123456789');
      expect(message.author.userId, '987654321');
      expect(message.author.login, 'sender_channel');
      expect(message.author.displayName, 'sender_name');
      expect(message.author.usernameColor, '#FF5733');
      expect(message.author.badges.map((b) => b.type),
          ['moderator', 'sub_gifter', 'subscriber']);
      expect(message.isSubscriber, isTrue);
      expect(message.author.provider, 'kick');
      expect(message.reply!.messageId, 'kick:unique_message_id_456');
      expect(message.reply!.author.login, 'parent_sender_channel');
    });

    test('tokenizes inline emotes', () {
      final message = append<KickMessageModel>('chat.message.sent');
      expect(message.tokenized, [
        const TextToken('Hello '),
        EmoteToken(url: kickEmoteUrl('4148074'), code: 'HYPERCLAP'),
        const TextToken(' '),
        EmoteToken(url: kickEmoteUrl('4148074'), code: 'HYPERCLAP'),
        const TextToken(' '),
        EmoteToken(url: kickEmoteUrl('37226'), code: 'KEKW'),
      ]);
      expect(kickEmoteUrl('37226').toString(),
          'https://files.kick.com/emotes/37226/fullsize');
    });

    test('tokenizes mentions and links', () {
      final message = KickMessageModel.fromEvent(
          messageId: 'kick:m',
          timestamp: timestamp,
          channelId: 'kick:1',
          event: {
            'sender': {'user_id': 1, 'username': 'A'},
            'content': 'hi @someone see https://kick.com',
          });
      expect(message.tokenized.whereType<UserMentionToken>().single.username,
          'someone');
      expect(
          message.tokenized.whereType<LinkToken>().single.url.host, 'kick.com');
      expect(message.isCommand, isFalse);
      expect(message.reply, isNull);
    });

    test('bans remove the banned user\'s messages', () {
      final chat = append<KickMessageModel>('chat.message.sent');
      final other = KickMessageModel.fromEvent(
          messageId: 'kick:other',
          timestamp: timestamp,
          channelId: 'kick:1',
          event: {
            'sender': {'user_id': 5, 'username': 'Other'},
            'content': 'hi',
          });
      final ban = fixture('moderation.banned');
      ban['banned_user']['user_id'] = 987654321;
      final event =
          toDeltaEvent(const [], 'kick:ban', doc('moderation.banned', ban));
      expect(event, isA<UpdateAllDeltaEvent>());
      final messages = applyDeltaEvent([chat, other], event!);
      expect((messages[0] as KickMessageModel).deleted, isTrue);
      expect((messages[1] as KickMessageModel).deleted, isFalse);
    });
  });

  group('events', () {
    test('follows', () {
      final follow = append<KickFollowEventModel>('channel.followed');
      expect(follow.follower.displayName, 'follower_name');
    });

    test('new and renewed subscriptions', () {
      final sub =
          append<KickSubscriptionEventModel>('channel.subscription.new');
      expect(sub.isRenewal, isFalse);
      expect(sub.months, 1);
      final renewal =
          append<KickSubscriptionEventModel>('channel.subscription.renewal');
      expect(renewal.isRenewal, isTrue);
      expect(renewal.months, 3);
    });

    test('gifted subscriptions, including anonymous gifters', () {
      final gifts = append<KickGiftedSubscriptionsEventModel>(
          'channel.subscription.gifts');
      expect(gifts.gifter!.displayName, 'gifter_name');
      expect(gifts.giftees.single.login, 'giftee_channel');
      final anonymous = append<KickGiftedSubscriptionsEventModel>(
          'channel.subscription.gifts', 'channel.subscription.gifts.anonymous');
      expect(anonymous.gifter, isNull);
    });

    test('kicks', () {
      final kicks = append<KicksGiftedEventModel>('kicks.gifted');
      expect(kicks.amount, 500);
      expect(kicks.giftName, 'Rage Quit');
      expect(kicks.message, 'w');
    });

    test('reward redemptions', () {
      final redemption = append<KickRewardRedemptionEventModel>(
          'channel.reward.redemption.updated');
      expect(redemption.rewardTitle, 'Uban Request');
      expect(redemption.cost, 1000);
      expect(redemption.userInput, 'unban me');
      expect(redemption.status, 'rejected');
      expect(redemption.redeemer.profilePictureUrl, isNull);
    });
  });
}
