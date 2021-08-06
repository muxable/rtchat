import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/twitch/event.dart';
import 'package:rtchat/models/twitch/message.dart';
import 'package:rtchat/models/twitch/subscription_event.dart';
import 'package:rtchat/models/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/twitch/subscription_message_event.dart';
import 'package:rtchat/models/twitch/user.dart';

class ChatHistoryModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;

  final List<MessageModel> _events = [];

  final _messageAdditionController = StreamController<TtsMessage>();
  final _messageDeletionController = StreamController<String>();

  ChatHistoryModel();

  Future<void> subscribe(Set<Channel> channels) async {
    final subscribe = FirebaseFunctions.instance.httpsCallable('subscribe');
    for (final channel in channels) {
      subscribe({
        "provider": channel.provider,
        "channelId": channel.channelId,
      });
    }

    _events.clear();
    notifyListeners();

    _subscription?.cancel();
    if (channels.isEmpty) {
      _subscription = null;
    } else {
      final channelIds = channels
          .map((channel) => "${channel.provider}:${channel.channelId}")
          .toList();
      _subscription = FirebaseFirestore.instance
          .collection("messages")
          .where("channelId", whereIn: channelIds)
          .orderBy("timestamp")
          .limitToLast(250)
          .snapshots()
          .expand((event) => event.docChanges)
          // only process appends.
          .where((change) => change.type == DocumentChangeType.added)
          .listen((change) {
        final data = change.doc.data();
        if (data == null) {
          return;
        }

        switch (data['type']) {
          case "message":
            final message = data['message'];
            final tags = data['tags'];

            final author = TwitchUserModel(
                displayName: tags['display-name'], login: tags['username']);

            final model = TwitchMessageModel(
                messageId: change.doc.id,
                author: author,
                message: message,
                tags: tags,
                timestamp: data['timestamp'].toDate(),
                deleted: false,
                channelId: data['channelId']);

            _events.add(model);
            _messageAdditionController.add(TtsMessage(
                messageId: change.doc.id,
                author: author,
                message: message,
                coalescingHeader: "${author.login} said",
                hasEmote: model.hasEmote,
                emotes: model.tags['emotes']));
            break;
          case "messagedeleted":
            final messageId = data['messageId'];
            final index = _events.indexWhere((element) {
              return element is TwitchMessageModel &&
                  element.messageId == messageId;
            });
            if (index > -1) {
              final message = _events[index];
              if (message is TwitchMessageModel) {
                _events[index] = TwitchMessageModel(
                    messageId: message.messageId,
                    author: message.author,
                    message: message.message,
                    tags: message.tags,
                    timestamp: message.timestamp,
                    deleted: true,
                    channelId: data['channelId']);
                _messageDeletionController.add(message.messageId);
              }
            }
            break;
          case "raided":
            final index = _events.length;
            final DateTime timestamp = data['timestamp'].toDate();
            final expiration = timestamp.add(const Duration(seconds: 15));
            final remaining = expiration.difference(DateTime.now());

            final model = TwitchRaidEventModel(
                messageId: change.doc.id,
                profilePictureUrl: data['tags']['msg-param-profileImageURL'],
                fromUsername: data['username'],
                viewers: data['viewers'],
                pinned: remaining > Duration.zero);
            _events.add(model);

            if (remaining > Duration.zero) {
              Timer(remaining, () {
                _events[index] = TwitchRaidEventModel(
                    messageId: change.doc.id,
                    profilePictureUrl: data['tags']
                        ['msg-param-profileImageURL'],
                    fromUsername: data['username'],
                    viewers: data['viewers'],
                    pinned: false);
                notifyListeners();
              });
            }
            break;
          case "channel.subscribe":
            final index = _events.length;
            final DateTime timestamp = data['timestamp'].toDate();
            final expiration = timestamp.add(const Duration(seconds: 15));
            final remaining = expiration.difference(DateTime.now());

            final model = TwitchSubscriptionEventModel(
                pinned: remaining > Duration.zero,
                messageId: change.doc.id,
                subscriberUserName: data['event']['user_name'],
                isGift: data['event']['is_gift'],
                tier: data['event']['tier']);

            _events.add(model);

            if (remaining > Duration.zero) {
              Timer(remaining, () {
                _events[index] = TwitchSubscriptionEventModel(
                    pinned: false,
                    messageId: change.doc.id,
                    subscriberUserName: data['event']['user_name'],
                    isGift: data['event']['is_gift'],
                    tier: data['event']['tier']);
                notifyListeners();
              });
            }

            break;
          case "channel.subscription.gift":
            final index = _events.length;
            final DateTime timestamp = data['timestamp'].toDate();
            final expiration = timestamp.add(const Duration(seconds: 15));
            final remaining = expiration.difference(DateTime.now());

            final gifterName = data['event']['is_anonymous']
                ? "Anonymous Gifter"
                : data['event']['user_name'];

            final model = TwitchSubscriptionGiftEventModel(
                pinned: remaining > Duration.zero,
                messageId: change.doc.id,
                gifterUserName: gifterName,
                tier: data['event']['tier'],
                total: data['event']['total']);

            _events.add(model);

            if (remaining > Duration.zero) {
              Timer(remaining, () {
                _events[index] = TwitchSubscriptionGiftEventModel(
                    pinned: false,
                    messageId: change.doc.id,
                    gifterUserName: gifterName,
                    tier: data['event']['tier'],
                    total: data['event']['total']);
                notifyListeners();
              });
            }

            break;
          case "channel.subscription.message":
            final index = _events.length;
            final DateTime timestamp = data['timestamp'].toDate();
            final expiration = timestamp.add(const Duration(seconds: 15));
            final remaining = expiration.difference(DateTime.now());

            final model = TwitchSubscriptionMessageEventModel(
                pinned: remaining > Duration.zero,
                messageId: change.doc.id,
                subscriberUserName: data['event']['user_name'],
                tier: data['event']['tier'],
                streakMonths: data['event']['streak_months'],
                cumulativeMonths: data['event']['cumulative_months'],
                durationMonths: data['event']['duration_months']);

            _events.add(model);

            if (remaining > Duration.zero) {
              Timer(remaining, () {
                _events[index] = TwitchSubscriptionMessageEventModel(
                    pinned: false,
                    messageId: change.doc.id,
                    subscriberUserName: data['event']['user_name'],
                    tier: data['event']['tier'],
                    streakMonths: data['event']['streak_months'],
                    cumulativeMonths: data['event']['cumulative_months'],
                    durationMonths: data['event']['duration_months']);
                notifyListeners();
              });
            }
            
            break;
          case "channel.follow":
            final model = TwitchFollowEventModel(
                followerName: data['event']['user_name'],
                messageId: change.doc.id,
                pinned: false);
            _events.add(model);
            break;
          case "stream.online":
          case "stream.offline":
            _events.add(StreamStateEventModel(
                messageId: change.doc.id,
                isOnline: data['type'] == "stream.online",
                timestamp: data['timestamp'].toDate()));
            break;
        }

        notifyListeners();
      }, onDone: () {
        FirebaseCrashlytics.instance
            .log("unexpected done handler called on firestore listener");
      }, onError: (error) {
        FirebaseCrashlytics.instance.recordError(error, StackTrace.current,
            reason: "messages listener error");
      });
    }
  }

  Stream<TtsMessage> get additions => _messageAdditionController.stream;

  Stream<String> get deletions => _messageDeletionController.stream;

  void clear() {
    _events.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageAdditionController.close();
    _messageDeletionController.close();
    super.dispose();
  }

  List<MessageModel> get messages => _events;
}
