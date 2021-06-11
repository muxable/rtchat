import 'dart:core';

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

class StreamMetadata {}

class TwitchStreamMetadata extends StreamMetadata {
  final int viewerCount;
  final int followerCount;
  final bool isOnline;

  TwitchStreamMetadata(
      {required this.viewerCount,
      required this.followerCount,
      required this.isOnline});
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
