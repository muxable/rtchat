import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';

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

  String get profilePictureUrl {
    return "https://us-central1-rtchat-47692.cloudfunctions.net/getProfilePicture?provider=twitch&channelId=$channelId";
  }
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
