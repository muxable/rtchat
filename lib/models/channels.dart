import 'dart:core';

import 'package:rtchat/components/image/resilient_network_image.dart';

class Channel {
  final String provider;
  final String channelId;
  final String displayName;
  final String? language;

  Channel(this.provider, this.channelId, this.displayName, {this.language});

  @override
  bool operator ==(other) =>
      other is Channel &&
      other.provider == provider &&
      other.channelId == channelId &&
      other.displayName == displayName;

  @override
  int get hashCode => provider.hashCode ^ channelId.hashCode;

  @override
  String toString() => "$provider:$channelId";

  Uri get profilePictureUrl {
    return Uri.parse(
        "https://rtirl.com/pfp.png?provider=twitch&channelId=$channelId");
  }

  ResilientNetworkImage get profilePicture {
    return ResilientNetworkImage(profilePictureUrl);
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'channelId': channelId,
      'displayName': displayName,
      'language': language,
    };
  }
}
