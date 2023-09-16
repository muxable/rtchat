import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ChannelMetadata {
  final DateTime? onlineAt;
  ChannelMetadata({required this.onlineAt});
}

class TwitchChannelMetadata extends ChannelMetadata {
  final int viewerCount;
  final int followerCount;
  final String? language;

  TwitchChannelMetadata(
      {required this.viewerCount,
      required this.followerCount,
      this.language,
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
              followerCount: data["followerCount"] ?? 0,
              language: data["language"]);
        default:
          return ChannelMetadata(
              onlineAt: (data["onlineAt"] as Timestamp?)?.toDate());
      }
    });
  }

  /// Returns the Twitch login for a given Twitch user ID. This is useful for
  /// IRC which uses the login instead of the display name.
  Future<String?> getLogin(Channel channel) async {
    final doc = await db.collection("channels").doc(channel.toString()).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return data["login"];
  }
}
