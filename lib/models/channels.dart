import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class Channel {
  final String provider;
  final String channelId;
  final String displayName;

  Channel(this.provider, this.channelId, this.displayName);

  bool operator ==(that) =>
      that is Channel &&
      that.provider == this.provider &&
      that.channelId == this.channelId;

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
  Set<Channel> _channels = {};

  Set<Channel> get channels {
    return _channels;
  }

  set channels(Set<Channel> channels) {
    _channels = channels;
    notifyListeners();
  }
}
