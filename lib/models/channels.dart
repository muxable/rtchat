import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/chat_history.dart';

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
  Stream<DeltaEvent> _chatHistory = const Stream.empty();

  set subscribedChannels(Set<Channel> channels) {
    _subscribedChannels = channels;
    for (final channel in channels) {
      if (!_availableChannels.contains(channel)) {
        _availableChannels.add(channel);
      }
    }
    _chatHistory = getChatHistory(channels).asBroadcastStream();
    notifyListeners();
  }

  Stream<DeltaEvent> get chatHistory => _chatHistory;

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
