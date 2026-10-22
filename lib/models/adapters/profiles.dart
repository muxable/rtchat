import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rtchat/models/channels.dart';

class ProfilesAdapter {
  final FirebaseFirestore db;

  ProfilesAdapter._({required this.db});

  static ProfilesAdapter get instance =>
      _instance ??= ProfilesAdapter._(db: FirebaseFirestore.instance);
  static ProfilesAdapter? _instance;

  /// Reads as the user signed in on [app], for owner-only profiles.
  static ProfilesAdapter forApp(FirebaseApp app) =>
      _forApp[app.name] ??= ProfilesAdapter._(
        db: FirebaseFirestore.instanceFor(app: app),
      );
  static final Map<String, ProfilesAdapter> _forApp = {};

  /// The channel of the account [userId] signed in with.
  Stream<Channel?> getChannel({required String userId}) {
    return db
        .collection("profiles")
        .doc(userId)
        .snapshots()
        .map((event) => channelFromProfile(event.data()));
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
        .map(
          (event) =>
              event.docs.isNotEmpty &&
              event.docs.single.get("type") == "stream.online",
        );
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
Channel? channelFromProfile(Map<String, dynamic>? data) {
  for (final provider in Providers.all) {
    final account = data?[provider];
    if (account is! Map || account['id'] == null) {
      continue;
    }
    return Channel(
      provider,
      account['id'].toString(),
      account['displayName'] ?? account['slug'] ?? account['login'] ?? '',
    );
  }
  return null;
}
