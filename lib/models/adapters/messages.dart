import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

abstract class DeltaEvent {
  const DeltaEvent();
}

class AppendDeltaEvent extends DeltaEvent {
  final MessageModel model;

  const AppendDeltaEvent(this.model);
}

class UpdateDeltaEvent extends DeltaEvent {
  final String messageId;
  final MessageModel Function(MessageModel) update;

  const UpdateDeltaEvent(this.messageId, this.update);
}

DeltaEvent? _toDeltaEvent(Map<String, List<Emote>> emotes,
    DocumentChange<Map<String, dynamic>> change) {
  final data = change.doc.data();
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

      final model = TwitchMessageModel(
          messageId: change.doc.id,
          author: author,
          message: message,
          tags: tags,
          thirdPartyEmotes: emotes[data['channelId']]!,
          timestamp: data['timestamp'].toDate(),
          deleted: false,
          channelId: data['channelId']);

      return AppendDeltaEvent(model);
    case "messagedeleted":
      return UpdateDeltaEvent(data['messageId'], (message) {
        if (message is! TwitchMessageModel) {
          return message;
        }
        return TwitchMessageModel(
            messageId: message.messageId,
            author: message.author,
            message: message.message,
            tags: message.tags,
            thirdPartyEmotes: [],
            timestamp: message.timestamp,
            deleted: true,
            channelId: data['channelId']);
      });
    case "channel.raid":
      final model = TwitchRaidEventModel(
          messageId: change.doc.id,
          from: TwitchUserModel(
              userId: data['event']['from_broadcaster_user_id'],
              login: data['event']['from_broadcaster_user_login'],
              displayName: data['event']['from_broadcaster_user_name']),
          viewers: data['event']['viewers'],
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "channel.subscribe":
      final model = TwitchSubscriptionEventModel(
          timestamp: data['timestamp'].toDate(),
          messageId: change.doc.id,
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
          messageId: change.doc.id,
          gifterUserName: gifterName,
          tier: data['event']['tier'],
          total: data['event']['total'],
          cumulativeTotal: data['event']['cumulative_total'] ?? 0);

      return AppendDeltaEvent(model);
    case "channel.subscription.message":
      final model = TwitchSubscriptionMessageEventModel(
          timestamp: data['timestamp'].toDate(),
          messageId: change.doc.id,
          subscriberUserName: data['event']['user_name'],
          tier: data['event']['tier'],
          streakMonths: data['event']['streak_months'],
          cumulativeMonths: data['event']['cumulative_months'],
          durationMonths: data['event']['duration_months']);

      return AppendDeltaEvent(model);
    case "channel.follow":
      return AppendDeltaEvent(
          TwitchFollowEventModel.fromDocumentData(change.doc.id, data));
    case "channel.cheer":
      final model = TwitchCheerEventModel(
          bits: data['event']['bits'],
          isAnonymous: data['event']['is_anonymous'],
          cheerMessage: data['event']['message'],
          giverName: data['event']['user_name'],
          messageId: change.doc.id,
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
    case "channel.poll.begin":
      final model = TwitchPollEventModel.fromDocumentData(data);
      return AppendDeltaEvent(model);
    case "channel.poll.progress":
      return UpdateDeltaEvent("poll${data['event']['id']}", (message) {
        if (message is! TwitchPollEventModel) {
          return message;
        }
        return message.withProgress(data);
      });
    case "channel.poll.end":
      return UpdateDeltaEvent("poll${data['event']['id']}", (message) {
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
          (message) {
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
          (message) {
        if (message is! TwitchHypeTrainEventModel) {
          return message;
        }

        return message.withProgress(data);
      });
    case "channel.hype_train.end":
      return UpdateDeltaEvent("channel.hype_train-${data['event']['id']}",
          (message) {
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
          (message) {
        if (message is! TwitchPredictionEventModel) {
          return message;
        }
        return TwitchPredictionEventModel.fromDocumentData(data);
      });
    case "channel.prediction.end":
      return UpdateDeltaEvent("channel.prediction-${data['event']['id']}",
          (message) {
        if (message is! TwitchPredictionEventModel) {
          return message;
        }
        return TwitchPredictionEventModel.fromEndEvent(data);
      });
    case "stream.online":
    case "stream.offline":
      final model = StreamStateEventModel(
          messageId: change.doc.id,
          isOnline: data['type'] == "stream.online",
          timestamp: data['timestamp'].toDate());
      return AppendDeltaEvent(model);
  }
}

class MessagesAdapter {
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  MessagesAdapter._({required this.db, required this.functions});

  static MessagesAdapter get instance => _instance ??= MessagesAdapter._(
      db: FirebaseFirestore.instance, functions: FirebaseFunctions.instance);
  static MessagesAdapter? _instance;

  Stream<DeltaEvent> forChannels(Set<Channel> channels) async* {
    final subscribe = functions.httpsCallable('subscribe');
    for (final channel in channels) {
      subscribe({
        "provider": channel.provider,
        "channelId": channel.channelId,
      });
    }
    if (channels.isEmpty) {
      return;
    }
    Map<String, List<Emote>> emotes = {};
    for (final channel in channels) {
      emotes[channel.toString()] =
          await getThirdPartyEmotes(channel.provider, channel.channelId);
    }
    yield* db
        .collection("messages")
        .where("channelId",
            whereIn: channels.map((channel) => channel.toString()).toList())
        .orderBy("timestamp")
        .limitToLast(250)
        .snapshots()
        .expand((event) => event.docChanges)
        .where((change) => change.type == DocumentChangeType.added)
        .expand((change) sync* {
      final event = _toDeltaEvent(emotes, change);
      if (event != null) {
        yield event;
      }
    });
  }
}
