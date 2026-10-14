import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ProfilesAdapter {
  final FirebaseFirestore db;

  ProfilesAdapter._({required this.db});

  static ProfilesAdapter get instance =>
      _instance ??= ProfilesAdapter._(db: FirebaseFirestore.instance);
  static ProfilesAdapter? _instance;

  /// The channel of the account [userId] signed in with.
  /// The channels of the accounts linked to [userId], one per platform.
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

/// Reads the account stored at `profiles/{uid}.{provider}`. Each user signs in
/// with one platform, so a profile holds a single account.
/// The channels of every account linked to a profile, one per platform.
List<Channel> channelsFromProfile(Map<String, dynamic>? data) => [
      for (final provider in Providers.all)
        if (data?[provider] case {'id': final id} when id != null)
          Channel(
              provider,
              id.toString(),
              data![provider]['displayName'] ??
                  data[provider]['slug'] ??
                  data[provider]['login'] ??
                  ''),
    ];

/// The channel the user signed in with: their first linked account.
Channel? channelFromProfile(Map<String, dynamic>? data) =>
    channelsFromProfile(data).firstOrNull;
