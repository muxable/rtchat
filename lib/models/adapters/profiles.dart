import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/channels.dart';

class ProfilesAdapter {
  final FirebaseFirestore db;

  ProfilesAdapter._({required this.db});

  static ProfilesAdapter get instance =>
      _instance ??= ProfilesAdapter._(db: FirebaseFirestore.instance);
  static ProfilesAdapter? _instance;

  Stream<Channel?> getChannel(
      {required String userId, required String provider}) {
    return db.collection("profiles").doc(userId).snapshots().map((event) {
      if (!event.exists) {
        return null;
      }
      final data = event.get("twitch");
      return data != null
          ? Channel(provider, data['id'], data['displayName'])
          : null;
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
            event.docs.single.get("type") == "stream.online");
  }
}
