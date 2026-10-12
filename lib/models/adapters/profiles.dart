import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ProfilesAdapter {
  final FirebaseFirestore db;

  ProfilesAdapter._({required this.db});

  static ProfilesAdapter get instance =>
      _instance ??= ProfilesAdapter._(db: FirebaseFirestore.instance);
  static ProfilesAdapter? _instance;

  /// The channels of every account linked to [userId], Twitch first.
  Stream<List<Channel>> getChannels({required String userId}) {
    return db
        .collection("profiles")
        .doc(userId)
        .snapshots()
        .map((event) => channelsFromProfile(event.data()));
  }

  Stream<bool> getIsOnline({required String channelId}) {
    return db
        .collection("channels")
        .doc(channelId)
        .collection("messages")
        .where("type", whereIn: ["stream.online", "stream.offline"])
        .orderBy("timestamp")
        .limitToLast(1)
        .snapshots()
        .map((event) =>
            event.docs.isNotEmpty &&
            event.docs.single.get("type") == "stream.online");
  }

  Stream<bool> getIsAdsEnabled({required String userId}) {
    return db.collection("profiles").doc(userId).snapshots().map((doc) {
      return doc.exists && (doc.get("claims")['ads'] ?? false);
    });
  }

  Future<String> getCompanionAuthToken({required String sessionUuid}) async {
    final doc = await db
        .collection("companion-tokens")
        .doc(sessionUuid)
        .snapshots()
        .firstWhere((event) => event.exists);
    return doc.data()!["token"] as String;
  }
}

/// Reads the linked accounts stored at `profiles/{uid}.{provider}`.
List<Channel> channelsFromProfile(Map<String, dynamic>? data) {
  final channels = <Channel>[];
  for (final provider in [Providers.twitch, Providers.kick]) {
    final account = data?[provider];
    if (account is! Map || account['id'] == null) {
      continue;
    }
    channels.add(Channel(provider, account['id'].toString(),
        account['displayName'] ?? account['slug'] ?? account['login'] ?? ''));
  }
  return channels;
}
