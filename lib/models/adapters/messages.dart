import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/reply.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

abstract class DeltaEvent {
  final DateTime timestamp;

  const DeltaEvent(this.timestamp);
}

class AppendDeltaEvent extends DeltaEvent {
  final MessageModel model;

  AppendDeltaEvent(this.model) : super(model.timestamp);
}

class UpdateDeltaEvent extends DeltaEvent {
  final String messageId;
  final MessageModel Function(MessageModel) update;

  const UpdateDeltaEvent(this.messageId, DateTime timestamp, this.update)
    : super(timestamp);
}

class UpdateAllDeltaEvent extends DeltaEvent {
  final MessageModel Function(MessageModel) update;

  const UpdateAllDeltaEvent(super.timestamp, this.update);
}

class ClearDeltaEvent extends DeltaEvent {
  final String messageId;

  const ClearDeltaEvent({required this.messageId, required DateTime timestamp})
    : super(timestamp);
}

// this is a sentinel event to indicate that the messages that follow are
// live messages.
class LiveStateDeltaEvent extends DeltaEvent {
  const LiveStateDeltaEvent(super.timestamp);
}

DeltaEvent? _toDeltaEvent(
  Channel channel,
  List<Emote> emotes,
  DocumentSnapshot<Map<String, dynamic>> doc,
) => toChannelDeltaEvent(channel, emotes, doc.id, doc.data());

/// Parses a message document from [channel], tagging new messages with it.
@visibleForTesting
DeltaEvent? toChannelDeltaEvent(
  Channel channel,
  List<Emote> emotes,
  String id,
  Map<String, dynamic>? data,
) {
  final event = toDeltaEvent(emotes, id, data);
  if (event is AppendDeltaEvent) {
    event.model.channel = channel;
  }
  return event;
}

@visibleForTesting
DeltaEvent? toDeltaEvent(
  List<Emote> emotes,
  String id,
  Map<String, dynamic>? data,
) {
  if (data == null) {
    return null;
  }

  switch (data['type']) {
    case "message":
      final message = data['message'];
      final tags = data['tags'];

      final author = TwitchUserModel(
        userId: tags['user-id'],
        displayName: tags['display-name'],
        login: tags['username'],
      );

      final reply =
          data['reply'] != null
              ? TwitchMessageReplyModel(
                messageId: data['reply']['messageId'],
                message: data['reply']['message'],
                author: TwitchUserModel(
                  userId: data['reply']['userId'],
                  displayName: data['reply']['displayName'],
                  login: data['reply']['userLogin'],
                ),
              )
              : null;

      final model = TwitchMessageModel(
        messageId: id,
        author: author,
        message: message,
        reply: reply,
        tags: tags,
        annotations: TwitchMessageAnnotationsModel.fromMap(data['annotations']),
        thirdPartyEmotes: emotes,
        timestamp: data['timestamp'].toDate(),
        deleted: false,
        channelId: data['channelId'],
      );

      return AppendDeltaEvent(model);
    case "messagedeleted":
      return UpdateDeltaEvent(data['messageId'], data['timestamp'].toDate(), (
        message,
      ) {
        if (message is! TwitchMessageModel) {
          return message;
        }
        return message.withDeleted(true);
      });
    case "channel.raid":
      final model = TwitchRaidEventModel(
        messageId: id,
        from: TwitchUserModel(
          userId: data['event']['from_broadcaster_user_id'],
          login: data['event']['from_broadcaster_user_login'],
          displayName: data['event']['from_broadcaster_user_name'],
        ),
        viewers: data['event']['viewers'],
        timestamp: data['timestamp'].toDate(),
      );
      return AppendDeltaEvent(model);
    case "clear":
      return ClearDeltaEvent(
        messageId: id,
        timestamp: data['timestamp'].toDate(),
      );
    case "userclear":
      return UpdateAllDeltaEvent(data['timestamp'].toDate(), (message) {
        if (message is! TwitchMessageModel ||
            message.author.userId != data['targetUserId']) {
          return message;
        }
        return message.withDeleted(true);
      });
    case "host":
      if (data['hosterChannelId'] == null) {
        // Since we might have some events saved without this field.
        return null;
      }
      final hosterInfo = data['hosterChannelId'].split(':');
      final model = TwitchHostEventModel(
        messageId: id,
        from: TwitchUserModel(
          userId: hosterInfo[1],
          login: data['displayName'],
          displayName: data['displayName'],
        ),
        viewers: data['viewers'],
        timestamp: data['timestamp'].toDate(),
      );
      return AppendDeltaEvent(model);
    case "channel.subscribe":
      final model = TwitchSubscriptionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: id,
        subscriberUserName: data['event']['user_name'],
        isGift: data['event']['is_gift'],
        tier: data['event']['tier'],
      );

      return AppendDeltaEvent(model);
    case "channel.subscription.gift":
      final gifterName =
          data['event']['is_anonymous']
              ? "Anonymous Gifter"
              : data['event']['user_name'];

      final model = TwitchSubscriptionGiftEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: id,
        gifterUserName: gifterName,
        tier: data['event']['tier'],
        total: data['event']['total'],
        cumulativeTotal: data['event']['cumulative_total'] ?? 0,
      );

      return AppendDeltaEvent(model);
    case "channel.subscription.message":
      final model = TwitchSubscriptionMessageEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: id,
        subscriberUserName: data['event']['user_name'],
        tier: data['event']['tier'],
        streakMonths: data['event']['streak_months'] ?? 0,
        cumulativeMonths: data['event']['cumulative_months'],
        durationMonths: data['event']['duration_months'] ?? 1,
        emotes: SubscriptionMessageEventEmote.fromDynamicList(
          data['event']['message']['emotes'],
        ),
        text: data['event']['message']['text'],
      );

      return AppendDeltaEvent(model);
    case "channel.follow":
      return AppendDeltaEvent(
        TwitchFollowEventModel.fromDocumentData(id, data),
      );
    case "channel.cheer":
      final model = TwitchCheerEventModel(
        bits: data['event']['bits'],
        isAnonymous: data['event']['is_anonymous'],
        cheerMessage: data['event']['message'],
        giverName: data['event']['user_name'],
        messageId: id,
        timestamp: data['timestamp'].toDate(),
      );
      return AppendDeltaEvent(model);
    case "channel.poll.begin":
      final model = TwitchPollEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.poll.progress":
      return UpdateDeltaEvent(
        "poll${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchPollEventModel) {
            return message;
          }
          return message.withProgress(data);
        },
      );
    case "channel.poll.end":
      return UpdateDeltaEvent(
        "poll${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchPollEventModel) {
            return message;
          }
          return message.withEnd(data);
        },
      );
    case "channel.channel_points_custom_reward_redemption.add":
      final model = TwitchChannelPointRedemptionEventModel.fromDocumentData(
        data,
      );
      return AppendDeltaEvent(model);
    case "channel.channel_points_custom_reward_redemption.update":
      return UpdateDeltaEvent(
        "channel.point-redemption-${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchChannelPointRedemptionEventModel) {
            return message;
          }
          return TwitchChannelPointRedemptionEventModel.fromDocumentData(data);
        },
      );
    case "channel.hype_train.begin":
      final model = TwitchHypeTrainEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.hype_train.progress":
      return UpdateDeltaEvent(
        "channel.hype_train-${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchHypeTrainEventModel) {
            return message;
          }

          return message.withProgress(data);
        },
      );
    case "channel.hype_train.end":
      return UpdateDeltaEvent(
        "channel.hype_train-${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchHypeTrainEventModel) {
            return message;
          }
          return message.withEnd(data);
        },
      );
    case "channel.prediction.begin":
      final model = TwitchPredictionEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.prediction.progress":
      return UpdateDeltaEvent(
        "channel.prediction-${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchPredictionEventModel) {
            return message;
          }
          return TwitchPredictionEventModel.fromDocumentData(data);
        },
      );
    case "channel.prediction.end":
      return UpdateDeltaEvent(
        "channel.prediction-${data['event']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchPredictionEventModel) {
            return message;
          }
          return TwitchPredictionEventModel.fromEndEvent(data);
        },
      );
    case "stream.online":
    case "stream.offline":
      final model = StreamStateEventModel(
        messageId: id,
        isOnline: data['type'] == "stream.online",
        timestamp: data['timestamp'].toDate(),
      );
      return AppendDeltaEvent(model);
    case "raid_update_v2":
      return AppendDeltaEvent(TwitchRaidingEventModel.fromDocumentData(data));
    case "raid_cancel_v2":
      return UpdateDeltaEvent(
        "raiding.${data['raid']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchRaidingEventModel) {
            return message;
          }
          return message.withCancel();
        },
      );
    case "raid_go_v2":
      return UpdateDeltaEvent(
        "raiding.${data['raid']['id']}",
        data['timestamp'].toDate(),
        (message) {
          if (message is! TwitchRaidingEventModel) {
            return message;
          }
          return message.withSuccessful();
        },
      );
    case "streamlabs.donation":
      final model = StreamlabsDonationEventModel.fromDocumentData(id, data);
      return AppendDeltaEvent(model);
    case "streamelements.tip":
      final model = StreamElementsTipEventModel.fromDocumentData(id, data);
      return AppendDeltaEvent(model);
    case "realtimecash.donation":
      final model = SimpleRealtimeCashDonationEventModel.fromDocumentData(
        id,
        data,
      );
      return AppendDeltaEvent(model);
    case "channel.shoutout.create":
      final model = TwitchShoutoutCreateEventModel.fromDocumentData(id, data);
      return AppendDeltaEvent(model);
    case "channel.shoutout.receive":
      final model = TwitchShoutoutReceiveEventModel.fromDocumentData(id, data);
      return AppendDeltaEvent(model);
    case "kick.chat.message.sent":
    case "kick.channel.followed":
    case "kick.channel.subscription.new":
    case "kick.channel.subscription.renewal":
    case "kick.channel.subscription.gifts":
    case "kick.kicks.gifted":
    case "kick.moderation.banned":
    case "kick.channel.reward.redemption.updated":
      return kickDeltaEvent(id, data);
  }
  return null;
}

typedef HistoryPage =
    ({List<DeltaEvent> events, DateTime? oldest, bool isLast});

class MessagesAdapter {
  final FirebaseFirestore db;

  MessagesAdapter._({required this.db});

  static MessagesAdapter get instance =>
      _instance ??= MessagesAdapter._(db: FirebaseFirestore.instance);
  static MessagesAdapter? _instance;

  /// Starts collecting [channel]'s chat. [api] should call as the account on
  /// [channel]'s provider: when it's that account's own channel, the backend
  /// also sets up its events and lists it in search.
  Future<void> subscribe(Channel channel, Api api) async {
    final subscribe = api.callable('subscribe');
    for (var i = 0; i < 3; i++) {
      try {
        await subscribe({
          "provider": channel.provider,
          "channelId": channel.channelId,
        });
        return;
      } catch (e, st) {
        if (i == 2) {
          FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  /// How many of a channel's latest messages its listener loads at first.
  /// Each one is a billed read on every channel open, so this is kept to
  /// about a screenful; older messages are paged in with [forChannelHistory]
  /// as chat is scrolled back.
  static const initialLoadSize = 50;

  /// How many older messages [forChannelHistory] loads per page.
  static const historyPageSize = 100;

  /// Loads the page of [channel]'s messages from before [from]. [oldest] is
  /// the timestamp of the oldest document in the page, whether or not it
  /// parsed into an event, to page back from next. [isLast] is set when the
  /// query returned fewer documents than a page, so there's nothing older.
  Future<HistoryPage> forChannelHistory(
    Channel channel,
    DateTime from,
    Api api,
  ) async {
    final emotes = await getEmotes(channel, api);

    final results =
        await db
            .collection("channels")
            .doc(channel.toString())
            .collection("messages")
            .where("timestamp", isLessThan: from)
            .orderBy("timestamp")
            .limitToLast(historyPageSize)
            .get();

    return (
      events:
          results.docs
              .map((doc) => _toDeltaEvent(channel, emotes, doc))
              .whereType<DeltaEvent>()
              .toList(),
      oldest:
          (results.docs.firstOrNull?.data()['timestamp'] as Timestamp?)
              ?.toDate(),
      isLast: results.docs.length < historyPageSize,
    );
  }

  Stream<DeltaEvent> forChannel(Channel channel, Api api) {
    subscribe(channel, api);
    final emotes = getEmotes(channel, api);
    var isInitialSnapshot = true;
    return db
        .collection("channels")
        .doc(channel.toString())
        .collection("messages")
        .orderBy("timestamp")
        .limitToLast(initialLoadSize)
        .snapshots()
        .asyncExpand((snapshot) async* {
          final changes = snapshot.docChanges.where(
            (change) => change.type == DocumentChangeType.added,
          );
          for (final change in changes) {
            try {
              final event = _toDeltaEvent(channel, await emotes, change.doc);
              if (event != null) {
                yield event;
              }
            } catch (e, st) {
              // send this report immediately.
              FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
            }
          }
          if (isInitialSnapshot &&
              changes.isNotEmpty &&
              !snapshot.metadata.isFromCache) {
            isInitialSnapshot = false;
            yield LiveStateDeltaEvent(DateTime.now());
          }
        });
  }

  /// Returns a stream of the "stream online" time.
  /// null indicates that the stream is offline.
  Stream<DateTime?> forChannelUptime(Channel channel, {DateTime? timestamp}) {
    var query = db
        .collection("channels")
        .doc(channel.toString())
        .collection("messages")
        .where("type", whereIn: ["stream.online", "stream.offline"]);
    if (timestamp != null) {
      query = query.where("timestamp", isLessThan: timestamp);
    }
    return query.orderBy("timestamp").limitToLast(1).snapshots().map((event) {
      if (event.docs.isEmpty) {
        return null;
      }
      final doc = event.docs.first;
      final data = doc.data();
      if (data['type'] == "stream.offline") {
        return null;
      }
      return data['timestamp'].toDate();
    });
  }

  Future<bool> hasMessages(Channel channel) async {
    return await db
        .collection("channels")
        .doc(channel.toString())
        .collection("messages")
        .where("channelId", isEqualTo: channel.toString())
        .limit(1)
        .get()
        .then((snapshot) => snapshot.docs.isNotEmpty);
  }
}

/// Parses the documents written by the backend's Kick webhook, which wrap
/// Kick's webhook payload in `event`.
DeltaEvent? kickDeltaEvent(String id, Map<String, dynamic> data) {
  final event = Map<String, dynamic>.from(data['event'] ?? {});
  final DateTime timestamp = data['timestamp'].toDate();
  KickUserModel user(String key) =>
      KickUserModel.fromJson(Map<String, dynamic>.from(event[key] ?? {}));

  switch (data['type']) {
    case "kick.chat.message.sent":
      return AppendDeltaEvent(
        KickMessageModel.fromEvent(
          messageId: id,
          timestamp: timestamp,
          channelId: data['channelId'],
          event: event,
        ),
      );
    case "kick.channel.followed":
      return AppendDeltaEvent(
        KickFollowEventModel(
          messageId: id,
          timestamp: timestamp,
          follower: user('follower'),
        ),
      );
    case "kick.channel.subscription.new":
    case "kick.channel.subscription.renewal":
      return AppendDeltaEvent(
        KickSubscriptionEventModel(
          messageId: id,
          timestamp: timestamp,
          subscriber: user('subscriber'),
          months: event['duration'] ?? 1,
          isRenewal: data['type'] == "kick.channel.subscription.renewal",
        ),
      );
    case "kick.channel.subscription.gifts":
      final gifter = event['gifter'];
      return AppendDeltaEvent(
        KickGiftedSubscriptionsEventModel(
          messageId: id,
          timestamp: timestamp,
          gifter:
              gifter == null || gifter['is_anonymous'] == true
                  ? null
                  : user('gifter'),
          giftees: [
            for (final giftee in (event['giftees'] as List?) ?? const [])
              KickUserModel.fromJson(Map<String, dynamic>.from(giftee)),
          ],
        ),
      );
    case "kick.kicks.gifted":
      final gift = event['gift'] ?? {};
      final message = gift['message'] as String?;
      return AppendDeltaEvent(
        KicksGiftedEventModel(
          messageId: id,
          timestamp: timestamp,
          sender: user('sender'),
          amount: gift['amount'] ?? 0,
          giftName: gift['name'] ?? '',
          message: message == null || message.isEmpty ? null : message,
        ),
      );
    case "kick.moderation.banned":
      // like a twitch userclear: the user's messages are removed.
      final bannedUserId = event['banned_user']?['user_id']?.toString();
      return UpdateAllDeltaEvent(timestamp, (message) {
        if (message is! KickMessageModel ||
            message.author.userId != bannedUserId) {
          return message;
        }
        return message.withDeleted(true);
      });
    case "kick.channel.reward.redemption.updated":
      final reward = event['reward'] ?? {};
      final input = event['user_input'] as String?;
      return AppendDeltaEvent(
        KickRewardRedemptionEventModel(
          messageId: id,
          timestamp: timestamp,
          redeemer: user('redeemer'),
          rewardTitle: reward['title'] ?? '',
          cost: reward['cost'] ?? 0,
          status: event['status'] ?? '',
          userInput: input == null || input.isEmpty ? null : input,
        ),
      );
  }
  return null;
}
