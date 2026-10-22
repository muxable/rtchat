import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';

class ChannelMetadata {
  final DateTime? onlineAt;
  ChannelMetadata({required this.onlineAt});
}

/// Metadata for a channel on a streaming platform.
class StreamChannelMetadata extends ChannelMetadata {
  final int viewerCount;

  /// Null when the platform doesn't report it.
  final int? followerCount;
  final String? language;
  final String? title;

  StreamChannelMetadata({
    required this.viewerCount,
    this.followerCount,
    this.language,
    this.title,
    required super.onlineAt,
  });
}

class TwitchChannelMetadata extends StreamChannelMetadata {
  TwitchChannelMetadata({
    required super.viewerCount,
    required int super.followerCount,
    super.language,
    super.title,
    required super.onlineAt,
  });

  @override
  int get followerCount => super.followerCount!;
}

/// Kick's API doesn't report follower counts, so [followerCount] is only set
/// once the backend has counted follows.
class KickChannelMetadata extends StreamChannelMetadata {
  KickChannelMetadata({
    required super.viewerCount,
    super.followerCount,
    super.language,
    super.title,
    required super.onlineAt,
  });
}

class ChannelsAdapter {
  final FirebaseFirestore db;

  ChannelsAdapter._({required this.db});

  static ChannelsAdapter get instance =>
      _instance ??= ChannelsAdapter._(db: FirebaseFirestore.instance);
  static ChannelsAdapter? _instance;

  Stream<ChannelMetadata> forChannel(Channel channel) {
    return db
        .collection("channels")
        .doc(channel.toString())
        .snapshots()
        .map((event) => channelMetadataFromData(channel, event.data()));
  }
}

/// Reads the metadata stored on `channels/{provider:id}`.
@visibleForTesting
ChannelMetadata channelMetadataFromData(
  Channel channel,
  Map<String, dynamic>? data,
) {
  if (data == null) {
    return ChannelMetadata(onlineAt: null);
  }
  switch (channel.provider) {
    case Providers.twitch:
      return TwitchChannelMetadata(
        onlineAt: (data["onlineAt"] as Timestamp?)?.toDate(),
        viewerCount: data["viewerCount"] ?? 0,
        followerCount: data["followerCount"] ?? 0,
        language: data["language"],
        title: data["title"],
      );
    case Providers.kick:
      return KickChannelMetadata(
        onlineAt: (data["onlineAt"] as Timestamp?)?.toDate(),
        viewerCount: data["viewerCount"] ?? 0,
        followerCount: data["followerCount"],
        language: data["language"],
        title: data["title"],
      );
    default:
      return ChannelMetadata(
        onlineAt: (data["onlineAt"] as Timestamp?)?.toDate(),
      );
  }
}
