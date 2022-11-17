import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ChannelMetadata {
  final DateTime? onlineAt;
  ChannelMetadata({required this.onlineAt});
}

class TwitchChannelMetadata extends ChannelMetadata {
  final int viewerCount;
  final int followerCount;

  TwitchChannelMetadata(
      {required this.viewerCount,
      required this.followerCount,
      required DateTime? onlineAt})
      : super(onlineAt: onlineAt);
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
        .map((event) {
      final data = event.data();
      if (data == null) {
        return ChannelMetadata(onlineAt: null);
      }
      switch (channel.provider) {
        case "twitch":
          return TwitchChannelMetadata(
              onlineAt: (data["onlineAt"] as Timestamp?)?.toDate(),
              viewerCount: data["viewerCount"] ?? 0,
              followerCount: data["followerCount"] ?? 0);
        default:
          return ChannelMetadata(
              onlineAt: (data["onlineAt"] as Timestamp?)?.toDate());
      }
    });
  }
}
