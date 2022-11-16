import 'dart:core';

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

  Uri get profilePictureUrl {
    return Uri.parse(
        "https://rtirl.com/pfp.png?provider=twitch&channelId=$channelId");
  }
}
