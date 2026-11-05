import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';

/// The streaming platforms a [Channel] can belong to.
abstract final class Providers {
  static const twitch = 'twitch';
  static const kick = 'kick';

  static const all = [twitch, kick];
}

/// The user-facing name of a provider.
String providerName(String provider) {
  switch (provider) {
    case Providers.twitch:
      return 'Twitch';
    case Providers.kick:
      return 'Kick';
  }
  return provider;
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
      "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId",
    );
  }

  CachedNetworkImageProvider get profilePicture {
    return CachedNetworkImageProvider(profilePictureUrl.toString());
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
