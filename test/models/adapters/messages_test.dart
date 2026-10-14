import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

// Timestamp.toDate() returns local time.
final timestamp = DateTime(2024, 1, 2, 3, 4, 5);

Map<String, dynamic> doc(String type,
        [Map<String, dynamic> fields = const {}]) =>
    {'type': type, 'timestamp': Timestamp.fromDate(timestamp), ...fields};

T append<T extends MessageModel>(Map<String, dynamic> data,
    {String id = 'doc-id'}) {
  final event = toDeltaEvent(const [], id, data);
  expect(event, isA<AppendDeltaEvent>());
  final model = (event as AppendDeltaEvent).model;
  expect(model, isA<T>());
  expect(model.timestamp, timestamp);
  return model as T;
}

UpdateDeltaEvent update(Map<String, dynamic> data, String messageId) {
  final event = toDeltaEvent(const [], 'doc-id', data);
  expect(event, isA<UpdateDeltaEvent>());
  final update = event as UpdateDeltaEvent;
  expect(update.messageId, messageId);
  expect(update.timestamp, timestamp);
  return update;
}

TwitchMessageModel chatMessage(
        {String messageId = 'm1',
        String userId = 'u1',
        bool deleted = false}) =>
    TwitchMessageModel(
        messageId: messageId,
        author: TwitchUserModel(userId: userId, login: 'login$userId'),
        message: 'hello',
        tags: const {},
        annotations: const TwitchMessageAnnotationsModel(
            isAction: false, isFirstTimeChatter: false, announcement: null),
        thirdPartyEmotes: const [],
        timestamp: timestamp,
        deleted: deleted,
        channelId: 'twitch:1');

final otherModel = StreamStateEventModel(
    messageId: 'other', isOnline: true, timestamp: DateTime.utc(2024));

Map<String, dynamic> pollEvent({String? endedAt, String? status}) => {
      'id': 'p1',
      'title': 'Best color?',
      'started_at': '2024-01-02T03:00:00Z',
      'ends_at': '2024-01-02T03:10:00Z',
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      'choices': [
        {'id': 'c1', 'title': 'Red', 'votes': 3},
        {'id': 'c2', 'votes': 5},
      ],
    };

Map<String, dynamic> hypeTrainEvent(
        {int level = 2, int total = 300, String? endedAt}) =>
    {
      'id': 'h1',
      'level': level,
      'progress': 50,
      'goal': 100,
      'total': total,
      'started_at': '2024-01-02T03:00:00Z',
      'expires_at': '2024-01-02T03:05:00Z',
      if (endedAt != null) 'ended_at': endedAt,
    };

Map<String, dynamic> predictionEvent(
        {String? status, String? winner, String? endedAt}) =>
    {
      'id': 'pr1',
      'title': 'Will we win?',
      'locks_at': '2024-01-02T03:10:00Z',
      if (status != null) 'status': status,
      if (winner != null) 'winning_outcome_id': winner,
      if (endedAt != null) 'ended_at': endedAt,
      'outcomes': [
        {'id': 'o1', 'title': 'Yes', 'color': 'blue', 'channel_points': 100},
        {'id': 'o2', 'title': 'No', 'color': 'pink', 'channel_points': 50},
      ],
    };

Map<String, dynamic> raid() => {
      'id': 'r1',
      'force_raid_now_seconds': 90,
      'target_id': 't1',
      'target_display_name': 'Target',
      'target_login': 'target',
    };

void main() {
  group('toDeltaEvent', () {
    test('null data returns null', () {
      expect(toDeltaEvent(const [], 'id', null), isNull);
    });

    test('unknown type returns null', () {
      expect(toDeltaEvent(const [], 'id', doc('not.a.real.type')), isNull);
    });

    test('message', () {
      final model = append<TwitchMessageModel>(doc('message', {
        'message': 'hi there',
        'channelId': 'twitch:1',
        'tags': {
          'user-id': 'u1',
          'display-name': 'User',
          'username': 'user',
        },
        'annotations': {'isAction': true, 'isFirstTimeChatter': false},
      }));
      expect(model.messageId, 'doc-id');
      expect(model.message, 'hi there');
      expect(model.channelId, 'twitch:1');
      expect(model.author.userId, 'u1');
      expect(model.author.login, 'user');
      expect(model.author.displayName, 'User');
      expect(model.isAction, isTrue);
      expect(model.deleted, isFalse);
      expect(model.reply, isNull);
    });

    test('message without annotations defaults them', () {
      final model = append<TwitchMessageModel>(doc('message', {
        'message': 'hi',
        'channelId': 'twitch:1',
        'tags': {'user-id': 'u1', 'username': 'user'},
      }));
      expect(model.isAction, isFalse);
      expect(model.annotations.isFirstTimeChatter, isFalse);
    });

    test('message with reply', () {
      final model = append<TwitchMessageModel>(doc('message', {
        'message': '@other yes',
        'channelId': 'twitch:1',
        'tags': {'user-id': 'u1', 'username': 'user'},
        'reply': {
          'messageId': 'parent',
          'message': 'question?',
          'userId': 'u2',
          'displayName': 'Other',
          'userLogin': 'other',
        },
      }));
      final reply = model.reply!;
      expect(reply.messageId, 'parent');
      expect(reply.message, 'question?');
      expect(reply.author.userId, 'u2');
      expect(reply.author.displayName, 'Other');
      expect(reply.author.login, 'other');
    });

    test('messagedeleted marks only twitch messages deleted', () {
      final event = update(doc('messagedeleted', {'messageId': 'm1'}), 'm1');
      final deleted = event.update(chatMessage()) as TwitchMessageModel;
      expect(deleted.deleted, isTrue);
      expect(deleted.messageId, 'm1');
      expect(event.update(otherModel), same(otherModel));
    });

    test('channel.raid', () {
      final model = append<TwitchRaidEventModel>(doc('channel.raid', {
        'event': {
          'from_broadcaster_user_id': 'b1',
          'from_broadcaster_user_login': 'raider',
          'from_broadcaster_user_name': 'Raider',
          'viewers': 42,
        },
      }));
      expect(model.messageId, 'doc-id');
      expect(model.from.userId, 'b1');
      expect(model.from.login, 'raider');
      expect(model.from.displayName, 'Raider');
      expect(model.viewers, 42);
    });

    test('clear', () {
      final event = toDeltaEvent(const [], 'clear-id', doc('clear'));
      expect(event, isA<ClearDeltaEvent>());
      expect((event as ClearDeltaEvent).messageId, 'clear-id');
      expect(event.timestamp, timestamp);
    });

    test('userclear deletes only the target user\'s messages', () {
      final event = toDeltaEvent(
          const [], 'id', doc('userclear', {'targetUserId': 'u1'}));
      expect(event, isA<UpdateAllDeltaEvent>());
      final update = (event as UpdateAllDeltaEvent).update;
      expect(event.timestamp, timestamp);
      expect((update(chatMessage(userId: 'u1')) as TwitchMessageModel).deleted,
          isTrue);
      final other = chatMessage(userId: 'u2');
      expect(update(other), same(other));
      expect(update(otherModel), same(otherModel));
    });

    test('host', () {
      final model = append<TwitchHostEventModel>(doc('host', {
        'hosterChannelId': 'twitch:123',
        'displayName': 'Hoster',
        'viewers': 7,
      }));
      expect(model.messageId, 'doc-id');
      expect(model.from.userId, '123');
      expect(model.from.login, 'Hoster');
      expect(model.from.displayName, 'Hoster');
      expect(model.viewers, 7);
    });

    test('host without hosterChannelId is ignored', () {
      expect(
          toDeltaEvent(const [], 'id', doc('host', {'displayName': 'Hoster'})),
          isNull);
    });

    test('channel.subscribe', () {
      final model =
          append<TwitchSubscriptionEventModel>(doc('channel.subscribe', {
        'event': {'user_name': 'Sub', 'is_gift': false, 'tier': '1000'}
      }));
      expect(model.messageId, 'doc-id');
      expect(model.subscriberUserName, 'Sub');
      expect(model.isGift, isFalse);
      expect(model.tier, '1000');
    });

    test('channel.subscription.gift', () {
      final model = append<TwitchSubscriptionGiftEventModel>(
          doc('channel.subscription.gift', {
        'event': {
          'is_anonymous': false,
          'user_name': 'Gifter',
          'tier': '2000',
          'total': 5,
          'cumulative_total': 20,
        }
      }));
      expect(model.gifterUserName, 'Gifter');
      expect(model.tier, '2000');
      expect(model.total, 5);
      expect(model.cumulativeTotal, 20);
    });

    test('anonymous channel.subscription.gift defaults cumulative total', () {
      final model = append<TwitchSubscriptionGiftEventModel>(
          doc('channel.subscription.gift', {
        'event': {
          'is_anonymous': true,
          'user_name': 'Hidden',
          'tier': '1000',
          'total': 1,
        }
      }));
      expect(model.gifterUserName, 'Anonymous Gifter');
      expect(model.cumulativeTotal, 0);
    });

    test('channel.subscription.message', () {
      final model = append<TwitchSubscriptionMessageEventModel>(
          doc('channel.subscription.message', {
        'event': {
          'user_name': 'Sub',
          'tier': '1000',
          'streak_months': 3,
          'cumulative_months': 12,
          'duration_months': 1,
          'message': {
            'text': 'Kappa love',
            'emotes': [
              {'id': '25', 'begin': 0, 'end': 4}
            ],
          },
        }
      }));
      expect(model.messageId, 'doc-id');
      expect(model.subscriberUserName, 'Sub');
      expect(model.streakMonths, 3);
      expect(model.cumulativeMonths, 12);
      expect(model.durationMonths, 1);
      expect(model.text, 'Kappa love');
      expect(model.emotes.single.id, '25');
      expect(model.emotes.single.begin, 0);
      expect(model.emotes.single.end, 4);
    });

    test('channel.subscription.message without a shared streak', () {
      // EventSub sends a null streak when the user doesn't share it.
      final model = append<TwitchSubscriptionMessageEventModel>(
          doc('channel.subscription.message', {
        'event': {
          'user_name': 'Sub',
          'tier': '2000',
          'streak_months': null,
          'cumulative_months': 12,
          'duration_months': 6,
          'message': {'text': '', 'emotes': null},
        }
      }));
      expect(model.streakMonths, 0);
      expect(model.durationMonths, 6);
      expect(model.emotes, isEmpty);
    });

    test('channel.follow', () {
      final model = append<TwitchFollowEventModel>(doc('channel.follow', {
        'event': {
          'user_id': 'f1',
          'user_login': 'follower',
          'user_name': 'Follower',
        }
      }));
      expect(model.messageId, 'doc-id');
      expect(model.followers.single.userId, 'f1');
      expect(model.followers.single.login, 'follower');
      expect(model.followers.single.displayName, 'Follower');
    });

    test('channel.cheer', () {
      final model = append<TwitchCheerEventModel>(doc('channel.cheer', {
        'event': {
          'bits': 100,
          'is_anonymous': false,
          'message': 'cheer100 nice',
          'user_name': 'Cheerer',
        }
      }));
      expect(model.messageId, 'doc-id');
      expect(model.bits, 100);
      expect(model.isAnonymous, isFalse);
      expect(model.cheerMessage, 'cheer100 nice');
      expect(model.giverName, 'Cheerer');
    });

    test('channel.poll.begin', () {
      final model = append<TwitchPollEventModel>(
          doc('channel.poll.begin', {'event': pollEvent()}));
      expect(model.messageId, 'pollp1');
      expect(model.pollTitle, 'Best color?');
      expect(model.isCompleted, isFalse);
      expect(model.status, 'ongoing');
      expect(model.choices.map((c) => c.title), ['Red', 'Untitled']);
      expect(model.totalVotes, 8);
    });

    test('channel.poll.progress and end update the poll', () {
      final begin = append<TwitchPollEventModel>(
          doc('channel.poll.begin', {'event': pollEvent()}));

      final progress = update(
          doc('channel.poll.progress', {'event': pollEvent()}), 'pollp1');
      final progressed = progress.update(begin) as TwitchPollEventModel;
      expect(progressed.isCompleted, isFalse);
      expect(progress.update(otherModel), same(otherModel));

      final end = update(
          doc('channel.poll.end', {
            'event':
                pollEvent(endedAt: '2024-01-02T03:09:00Z', status: 'completed')
          }),
          'pollp1');
      final ended = end.update(begin) as TwitchPollEventModel;
      expect(ended.isCompleted, isTrue);
      expect(ended.status, 'completed');
      expect(ended.endTimestamp, DateTime.utc(2024, 1, 2, 3, 9));
      expect(end.update(otherModel), same(otherModel));
    });

    test('channel point redemption add and update', () {
      Map<String, dynamic> event(String status) => {
            'id': 'cp1',
            'user_name': 'Redeemer',
            'status': status,
            'reward': {'title': 'Hydrate', 'cost': 500},
            'user_input': 'please',
          };
      final model = append<TwitchChannelPointRedemptionEventModel>(doc(
          'channel.channel_points_custom_reward_redemption.add',
          {'event': event('unfulfilled')}));
      expect(model.messageId, 'channel.point-redemption-cp1');
      expect(model.redeemerUsername, 'Redeemer');
      expect(model.rewardName, 'Hydrate');
      expect(model.rewardCost, 500);
      expect(model.userInput, 'please');
      expect(model.status, TwitchChannelPointRedemptionStatus.unfulfilled);

      final updateEvent = update(
          doc('channel.channel_points_custom_reward_redemption.update',
              {'event': event('fulfilled')}),
          'channel.point-redemption-cp1');
      final updated =
          updateEvent.update(model) as TwitchChannelPointRedemptionEventModel;
      expect(updated.status, TwitchChannelPointRedemptionStatus.fulfilled);
      expect(updateEvent.update(otherModel), same(otherModel));
    });

    test('hype train begin, progress and end', () {
      final model = append<TwitchHypeTrainEventModel>(
          doc('channel.hype_train.begin', {'event': hypeTrainEvent()}));
      expect(model.messageId, 'channel.hype_train-h1');
      expect(model.level, 2);

      final progress = update(
          doc('channel.hype_train.progress',
              {'event': hypeTrainEvent(level: 3, total: 400)}),
          'channel.hype_train-h1');
      final progressed = progress.update(model) as TwitchHypeTrainEventModel;
      expect(progressed.level, 3);
      expect(progressed.total, 400);
      expect(progress.update(otherModel), same(otherModel));

      final end = update(
          doc('channel.hype_train.end',
              {'event': hypeTrainEvent(endedAt: '2024-01-02T03:06:00Z')}),
          'channel.hype_train-h1');
      final ended = end.update(model) as TwitchHypeTrainEventModel;
      expect(ended.hasEnded, isTrue);
      expect(end.update(otherModel), same(otherModel));
    });

    test('prediction begin, progress and end', () {
      final model = append<TwitchPredictionEventModel>(
          doc('channel.prediction.begin', {'event': predictionEvent()}));
      expect(model.messageId, 'channel.prediction-pr1');
      expect(model.status, 'in_progress');
      expect(model.totalPoints, 150);

      final progress = update(
          doc('channel.prediction.progress', {'event': predictionEvent()}),
          'channel.prediction-pr1');
      expect(progress.update(model), isA<TwitchPredictionEventModel>());
      expect(progress.update(otherModel), same(otherModel));

      final end = update(
          doc('channel.prediction.end', {
            'event': predictionEvent(
                status: 'resolved',
                winner: 'o1',
                endedAt: '2024-01-02T03:20:00Z')
          }),
          'channel.prediction-pr1');
      final ended = end.update(model) as TwitchPredictionEventModel;
      expect(ended.status, 'resolved');
      expect(ended.winningOutcomeId, 'o1');
      expect(end.update(otherModel), same(otherModel));
    });

    test('stream.online and stream.offline', () {
      final online = append<StreamStateEventModel>(doc('stream.online'));
      expect(online.isOnline, isTrue);
      expect(online.messageId, 'doc-id');
      final offline = append<StreamStateEventModel>(doc('stream.offline'));
      expect(offline.isOnline, isFalse);
    });

    test('raid_update_v2, raid_cancel_v2 and raid_go_v2', () {
      final model = append<TwitchRaidingEventModel>(
          doc('raid_update_v2', {'raid': raid()}));
      expect(model.messageId, 'raiding.r1');
      expect(model.duration, const Duration(seconds: 90));
      expect(model.targetUser.userId, 't1');
      expect(model.isComplete, isFalse);

      final cancel =
          update(doc('raid_cancel_v2', {'raid': raid()}), 'raiding.r1');
      final cancelled = cancel.update(model) as TwitchRaidingEventModel;
      expect(cancelled.isComplete, isTrue);
      expect(cancelled.isSuccessful, isFalse);
      expect(cancel.update(otherModel), same(otherModel));

      final go = update(doc('raid_go_v2', {'raid': raid()}), 'raiding.r1');
      final succeeded = go.update(model) as TwitchRaidingEventModel;
      expect(succeeded.isComplete, isTrue);
      expect(succeeded.isSuccessful, isTrue);
      expect(go.update(otherModel), same(otherModel));
    });

    test('streamlabs.donation', () {
      final model =
          append<StreamlabsDonationEventModel>(doc('streamlabs.donation', {
        'name': 'Donor',
        'formattedAmount': '\$5.00',
        'message': 'thanks',
        'currency': 'USD',
      }));
      expect(model.messageId, 'doc-id');
      expect(model.name, 'Donor');
      expect(model.formattedAmount, '\$5.00');
      expect(model.message, 'thanks');
      expect(model.currency, 'USD');
    });

    test('streamelements.tip', () {
      final model =
          append<StreamElementsTipEventModel>(doc('streamelements.tip', {
        'name': 'Tipper',
        'formattedAmount': '€3.00',
        'message': 'hi',
        'currency': 'EUR',
      }));
      expect(model.messageId, 'doc-id');
      expect(model.name, 'Tipper');
      expect(model.currency, 'EUR');
    });

    test('realtimecash.donation', () {
      final model = append<SimpleRealtimeCashDonationEventModel>(
          doc('realtimecash.donation', {
        'activity': {'asset': 'MATIC', 'value': '0.5', 'hash': '0xabc'},
        'donor': 'Donor',
        'message': 'gm',
      }));
      expect(model.messageId, 'doc-id');
      expect(model.currency, 'MATIC');
      expect(model.value, 0.5);
      expect(model.hash, '0xabc');
      expect(model.donor, 'Donor');
      expect(model.message, 'gm');
    });

    test('channel.shoutout.create', () {
      final model = append<TwitchShoutoutCreateEventModel>(
          doc('channel.shoutout.create', {
        'event': {
          'broadcaster_user_id': 'b1',
          'broadcaster_user_name': 'Me',
          'to_broadcaster_user_id': 'b2',
          'to_broadcaster_user_name': 'Them',
          'viewer_count': 10,
        }
      }));
      expect(model.messageId, 'doc-id');
      expect(model.fromBroadcasterUserName, 'Me');
      expect(model.toBroadcasterUserName, 'Them');
      expect(model.viewerCount, 10);
    });

    test('channel.shoutout.receive', () {
      final model = append<TwitchShoutoutReceiveEventModel>(
          doc('channel.shoutout.receive', {
        'event': {
          'from_broadcaster_user_id': 'b2',
          'from_broadcaster_user_name': 'Them',
          'viewer_count': 20,
        }
      }));
      expect(model.messageId, 'doc-id');
      expect(model.fromBroadcasterUserName, 'Them');
      expect(model.viewerCount, 20);
    });
  });
}
