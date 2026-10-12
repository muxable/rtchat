import 'dart:core';

import 'package:rtchat/components/image/resilient_network_image.dart';

/// The streaming platforms a [Channel] can belong to.
abstract final class Providers {
  static const twitch = 'twitch';
  static const kick = 'kick';
}

class Channel {
  final String provider;
  final String channelId;
  final String displayName;
  final String? language;

  Channel(this.provider, this.channelId, this.displayName, {this.language});

  // a channel is identified by its provider and id; the display name can
  // change without it becoming a different channel.
  @override
  bool operator ==(other) =>
      other is Channel &&
      other.provider == provider &&
      other.channelId == channelId;

  @override
  int get hashCode => provider.hashCode ^ channelId.hashCode;

  @override
  String toString() => "$provider:$channelId";

  Uri get profilePictureUrl {
    return Uri.parse(
        "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId");
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
