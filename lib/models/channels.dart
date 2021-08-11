import 'dart:async';
import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rxdart/rxdart.dart';

class Channel {
  final String provider;
  final String channelId;
  final String displayName;

  Channel(this.provider, this.channelId, this.displayName);

  @override
  bool operator ==(other) =>
      other is Channel &&
      other.provider == provider &&
      other.channelId == channelId;

  @override
  int get hashCode => provider.hashCode ^ channelId.hashCode;

  @override
  String toString() => "$provider:$channelId";
}

class StreamMetadata {
  final bool isOnline;
  StreamMetadata({required this.isOnline});
}

class TwitchStreamMetadata extends StreamMetadata {
  final int viewerCount;
  final int followerCount;

  TwitchStreamMetadata(
      {required this.viewerCount,
      required this.followerCount,
      required bool isOnline})
      : super(isOnline: isOnline);
}

final getStatistics = FirebaseFunctions.instance.httpsCallable("getStatistics");

Future<StreamMetadata> getStreamMetadata(
    {required String provider, required String channelId}) async {
  final statistics = await getStatistics({
    "provider": provider,
    "channelId": channelId,
  });

  switch (provider) {
    case "twitch":
      return TwitchStreamMetadata(
        isOnline: statistics.data['isOnline'] ?? false,
        viewerCount: statistics.data['viewers'] ?? 0,
        followerCount: statistics.data['followers'] ?? 0,
      );
  }
  throw "invalid provider";
}

class ChannelsModel extends ChangeNotifier {
  Set<Channel> _subscribedChannels = {};
  List<Channel> _availableChannels = [];

  Set<Channel> get subscribedChannels => _subscribedChannels;

  StreamSubscription<void>? _subscription;

  List<MessageModel> _messages = [];

  set subscribedChannels(Set<Channel> channels) {
    _subscribedChannels = channels;
    for (final channel in channels) {
      if (!_availableChannels.contains(channel)) {
        _availableChannels.add(channel);
      }
    }
    _messages = [];
    notifyListeners();

    _subscription?.cancel();
    if (channels.isNotEmpty) {
      _subscription =
          getChatHistory(channels).scan<List<MessageModel>>((acc, event, i) {
        if (event is AppendDeltaEvent) {
          acc.add(event.model);
        } else if (event is UpdateDeltaEvent) {
          for (var i = 0; i < acc.length; i++) {
            if (acc[i].messageId == event.messageId) {
              acc[i] = event.update(acc[i]);
            }
          }
        }
        return acc;
      }, []).listen((messages) {
        _messages = messages;
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  List<Channel> get availableChannels => _availableChannels;

  set availableChannels(List<Channel> channels) {
    _availableChannels = channels;
    notifyListeners();
  }

  void addAvailableChannel(Channel channel) {
    if (!_availableChannels.contains(channel)) {
      _availableChannels.add(channel);
    }
  }
}
