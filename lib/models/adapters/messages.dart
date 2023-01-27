import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/reply.dart';
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

  const UpdateAllDeltaEvent(DateTime timestamp, this.update) : super(timestamp);
}

class ClearDeltaEvent extends DeltaEvent {
  final String messageId;

  const ClearDeltaEvent({
    required this.messageId,
    required DateTime timestamp,
  }) : super(timestamp);
}

// this is a sentinel event to indicate that the messages that follow are
// live messages.
class LiveStateDeltaEvent extends DeltaEvent {
  const LiveStateDeltaEvent(DateTime timestamp) : super(timestamp);
}

DeltaEvent? _toDeltaEvent(
    List<Emote> emotes, DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
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
          login: tags['username']);

      final reply = data['reply'] != null
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
          messageId: doc.id,
          author: author,
          message: message,
          reply: reply,
          tags: tags,
          annotations:
              TwitchMessageAnnotationsModel.fromMap(data['annotations']),
          thirdPartyEmotes: emotes,
          timestamp: data['timestamp'].toDate(),
          deleted: false,
          channelId: data['channelId']);

      return AppendDeltaEvent(model);
    case "messagedeleted":
      return UpdateDeltaEvent(data['messageId'], data['timestamp'].toDate(),
          (message) {
        if (message is! TwitchMessageModel) {
          return message;
        }
        return message.withDeleted(true);
      });
    case "channel.raid":
      final model = TwitchRaidEventModel(
          messageId: doc.id,
          from: TwitchUserModel(
              userId: data['event']['from_broadcaster_user_id'],
              login: data['event']['from_broadcaster_user_login'],
              displayName: data['event']['from_broadcaster_user_name']),
          viewers: data['event']['viewers'],
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "clear":
      return ClearDeltaEvent(
        messageId: doc.id,
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
          messageId: doc.id,
          from: TwitchUserModel(
              userId: hosterInfo[1],
              login: data['displayName'],
              displayName: data['displayName']),
          viewers: data['viewers'],
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "channel.subscribe":
      final model = TwitchSubscriptionEventModel(
          timestamp: data['timestamp'].toDate(),
          messageId: doc.id,
          subscriberUserName: data['event']['user_name'],
          isGift: data['event']['is_gift'],
          tier: data['event']['tier']);

      return AppendDeltaEvent(model);
    case "channel.subscription.gift":
      final gifterName = data['event']['is_anonymous']
          ? "Anonymous Gifter"
          : data['event']['user_name'];

      final model = TwitchSubscriptionGiftEventModel(
          timestamp: data['timestamp'].toDate(),
          messageId: doc.id,
          gifterUserName: gifterName,
          tier: data['event']['tier'],
          total: data['event']['total'],
          cumulativeTotal: data['event']['cumulative_total'] ?? 0);

      return AppendDeltaEvent(model);
    case "channel.subscription.message":
      final model = TwitchSubscriptionMessageEventModel(
          timestamp: data['timestamp'].toDate(),
          messageId: doc.id,
          subscriberUserName: data['event']['user_name'],
          tier: data['event']['tier'],
          streakMonths: data['event']['streak_months'],
          cumulativeMonths: data['event']['cumulative_months'],
          durationMonths: data['event']['duration_months'],
          emotes: SubscriptionMessageEventEmote.fromDynamicList(
              data['event']['message']['emotes']),
          text: data['event']['message']['text']);

      return AppendDeltaEvent(model);
    case "channel.follow":
      return AppendDeltaEvent(
          TwitchFollowEventModel.fromDocumentData(doc.id, data));
    case "channel.cheer":
      final model = TwitchCheerEventModel(
          bits: data['event']['bits'],
          isAnonymous: data['event']['is_anonymous'],
          cheerMessage: data['event']['message'],
          giverName: data['event']['user_name'],
          messageId: doc.id,
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "channel.poll.begin":
      final model = TwitchPollEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.poll.progress":
      return UpdateDeltaEvent(
          "poll${data['event']['id']}", data['timestamp'].toDate(), (message) {
        if (message is! TwitchPollEventModel) {
          return message;
        }
        return message.withProgress(data);
      });
    case "channel.poll.end":
      return UpdateDeltaEvent(
          "poll${data['event']['id']}", data['timestamp'].toDate(), (message) {
        if (message is! TwitchPollEventModel) {
          return message;
        }
        return message.withEnd(data);
      });
    case "channel.channel_points_custom_reward_redemption.add":
      final model =
          TwitchChannelPointRedemptionEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.channel_points_custom_reward_redemption.update":
      return UpdateDeltaEvent("channel.point-redemption-${data['event']['id']}",
          data['timestamp'].toDate(), (message) {
        if (message is! TwitchChannelPointRedemptionEventModel) {
          return message;
        }
        return TwitchChannelPointRedemptionEventModel.fromDocumentData(data);
      });
    case "channel.hype_train.begin":
      final model = TwitchHypeTrainEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.hype_train.progress":
      return UpdateDeltaEvent("channel.hype_train-${data['event']['id']}",
          data['timestamp'].toDate(), (message) {
        if (message is! TwitchHypeTrainEventModel) {
          return message;
        }

        return message.withProgress(data);
      });
    case "channel.hype_train.end":
      return UpdateDeltaEvent("channel.hype_train-${data['event']['id']}",
          data['timestamp'].toDate(), (message) {
        if (message is! TwitchHypeTrainEventModel) {
          return message;
        }
        return message.withEnd(data);
      });
    case "channel.prediction.begin":
      final model = TwitchPredictionEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.prediction.progress":
      return UpdateDeltaEvent("channel.prediction-${data['event']['id']}",
          data['timestamp'].toDate(), (message) {
        if (message is! TwitchPredictionEventModel) {
          return message;
        }
        return TwitchPredictionEventModel.fromDocumentData(data);
      });
    case "channel.prediction.end":
      return UpdateDeltaEvent("channel.prediction-${data['event']['id']}",
          data['timestamp'].toDate(), (message) {
        if (message is! TwitchPredictionEventModel) {
          return message;
        }
        return TwitchPredictionEventModel.fromEndEvent(data);
      });
    case "stream.online":
    case "stream.offline":
      final model = StreamStateEventModel(
          messageId: doc.id,
          isOnline: data['type'] == "stream.online",
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "raid_update_v2":
      return AppendDeltaEvent(TwitchRaidingEventModel.fromDocumentData(data));
    case "raid_cancel_v2":
      return UpdateDeltaEvent(
          "raiding.${data['raid']['id']}", data['timestamp'].toDate(),
          (message) {
        if (message is! TwitchRaidingEventModel) {
          return message;
        }
        return message.withCancel();
      });
    case "raid_go_v2":
      return UpdateDeltaEvent(
          "raiding.${data['raid']['id']}", data['timestamp'].toDate(),
          (message) {
        if (message is! TwitchRaidingEventModel) {
          return message;
        }
        return message.withSuccessful();
      });
    case "streamlabs.donation":
      final model = StreamlabsDonationEventModel.fromDocumentData(doc.id, data);
      return AppendDeltaEvent(model);
    case "realtimecash.donation":
      final model =
          SimpleRealtimeCashDonationEventModel.fromDocumentData(doc.id, data);
      return AppendDeltaEvent(model);
  }
  return null;
}

class MessagesAdapter {
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  MessagesAdapter._({required this.db, required this.functions});

  static MessagesAdapter get instance => _instance ??= MessagesAdapter._(
      db: FirebaseFirestore.instance, functions: FirebaseFunctions.instance);
  static MessagesAdapter? _instance;

  Future<void> subscribe(Channel channel) async {
    final subscribe = functions.httpsCallable('subscribe');
    await subscribe({
      "provider": channel.provider,
      "channelId": channel.channelId,
    });
  }

  Future<List<DeltaEvent>> forChannelHistory(
      Channel channel, DateTime from) async {
    final emotes = await getEmotes(channel);

    final results = await db
        .collection("channels")
        .doc(channel.toString())
        .collection("messages")
        .where("timestamp", isLessThan: from)
        .orderBy("timestamp")
        .limitToLast(250)
        .get();

    return results.docs
        .map((doc) => _toDeltaEvent(emotes, doc))
        .whereType<DeltaEvent>()
        .toList();
  }

  Stream<DeltaEvent> forChannel(Channel channel) {
    subscribe(channel);
    final emotes = getEmotes(channel);
    var lastAdTimestamp = DateTime.now();
    var lastAdMessageCount = 0;
    var isInitialSnapshot = true;
    return db
        .collection("channels")
        .doc(channel.toString())
        .collection("messages")
        .orderBy("timestamp")
        .limitToLast(250)
        .snapshots()
        .asyncExpand((snapshot) async* {
      final changes = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added);
      for (final change in changes) {
        try {
          final event = _toDeltaEvent(await emotes, change.doc);
          if (event != null) {
            yield event;
            lastAdMessageCount++;
          }
        } catch (e, st) {
          // send this report immediately.
          FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
        }
        // if there have been at least five minutes since the last ad, show one.
        if (DateTime.now().difference(lastAdTimestamp) >
                (kDebugMode
                    ? const Duration(seconds: 1)
                    : const Duration(minutes: 5)) &&
            // ensure that there are also at least 50 messages in between ads.
            lastAdMessageCount > 50 &&
            !isInitialSnapshot) {
          lastAdTimestamp = DateTime.now();
          lastAdMessageCount = 0;
          yield AppendDeltaEvent(
              AdMessageModel(adId: AdHelper.chatHistoryAdId));
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
