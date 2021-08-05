import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/third_party_emote.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rxdart/rxdart.dart';

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

Stream<DeltaEvent> _handleDocumentChange(
    Map<String, List<ThirdPartyEmote>> emotes,
    DocumentChange<Map<String, dynamic>> change) async* {
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
          thirdPartyEmotes: emotes[data['channelId']]!,
          timestamp: data['timestamp'].toDate(),
          deleted: false,
          channelId: data['channelId']);

      yield AppendDeltaEvent(model);
      break;
    case "messagedeleted":
      yield UpdateDeltaEvent(data['messageId'], (message) {
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
      break;
    case "raided":
      final DateTime timestamp = data['timestamp'].toDate();
      final expiration = timestamp.add(const Duration(seconds: 15));
      final remaining = expiration.difference(DateTime.now());

      final model = TwitchRaidEventModel(
          messageId: change.doc.id,
          profilePictureUrl: data['tags']['msg-param-profileImageURL'],
          fromUsername: data['username'],
          viewers: data['viewers'],
          pinned: remaining > Duration.zero);
      yield AppendDeltaEvent(model);

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
        yield UpdateDeltaEvent(change.doc.id, (message) {
          if (message is! TwitchRaidEventModel) {
            return message;
          }
          return TwitchRaidEventModel(
              messageId: change.doc.id,
              profilePictureUrl: data['tags']['msg-param-profileImageURL'],
              fromUsername: data['username'],
              viewers: data['viewers'],
              pinned: false);
        });
      }
      break;
    case "stream.online":
    case "stream.offline":
      final model = StreamStateEventModel(
          messageId: change.doc.id,
          isOnline: data['type'] == "stream.online",
          timestamp: data['timestamp'].toDate());
      yield AppendDeltaEvent(model);
  }
}

Stream<DeltaEvent> getChatHistory(Set<Channel> channels) async* {
  final subscribe = FirebaseFunctions.instance.httpsCallable('subscribe');
  for (final channel in channels) {
    subscribe({
      "provider": channel.provider,
      "channelId": channel.channelId,
    });
  }
  if (channels.isEmpty) {
    return;
  }
  Map<String, List<ThirdPartyEmote>> emotes = {};
  for (final channel in channels) {
    emotes[channel.toString()] =
        await getThirdPartyEmotes(channel.provider, channel.channelId);
  }
  yield* FirebaseFirestore.instance
      .collection("messages")
      .where("channelId",
          whereIn: channels.map((channel) => channel.toString()).toList())
      .orderBy("timestamp")
      .limitToLast(250)
      .snapshots()
      .expand((event) => event.docChanges)
      .where((change) => change.type == DocumentChangeType.added)
      .flatMap((change) => _handleDocumentChange(emotes, change));
}
