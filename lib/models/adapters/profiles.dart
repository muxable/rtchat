import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ProfilesAdapter {
  static final Map<FirebaseFirestore, ProfilesAdapter> _cachedInstances = {};

  final FirebaseFirestore db;

  ProfilesAdapter._({required this.db});

  factory ProfilesAdapter.instanceFor({required FirebaseFirestore db}) {
    if (_cachedInstances.containsKey(db)) {
      return _cachedInstances[db]!;
    }

    final newInstance = ProfilesAdapter._(db: db);
    _cachedInstances[db] = newInstance;
    return newInstance;
  }

  static ProfilesAdapter get instance =>
      ProfilesAdapter.instanceFor(db: FirebaseFirestore.instance);

  Stream<Channel?> getChannel({required String userId}) {
    return db.collection("profiles").doc(userId).snapshots().map((event) {
      final data = event.data();
      if (data != null && data.containsKey('twitch')) {
        return Channel(
            "twitch", data['twitch']['id'], data['twitch']['displayName']);
      }
    });
  }

  Stream<bool> getIsOnline({required String channelId}) {
    return db
        .collection("messages")
        .where("channelId", isEqualTo: channelId)
        .where("type", whereIn: ["stream.online", "stream.offline"])
        .orderBy("timestamp")
        .limitToLast(1)
        .snapshots()
        .map((event) =>
            event.docs.isNotEmpty &&
            event.docs.first.get("type") == "stream.online");
  }
}
