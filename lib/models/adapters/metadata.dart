import 'package:cloud_firestore/cloud_firestore.dart';

class MetadataAdapter {
  final FirebaseFirestore db;

  MetadataAdapter._({required this.db});

  static MetadataAdapter get instance =>
      _instance ??= MetadataAdapter._(db: FirebaseFirestore.instance);
  static MetadataAdapter? _instance;

  Stream<String?> getThirdPartyMetadataValue(
      {required String channelId, required String name, required String key}) {
    return db
        .collection("channels")
        .doc(channelId)
        .collection("third-party")
        .where("name", isEqualTo: name)
        .where("key", isEqualTo: key)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .map((event) {
      if (event.docs.isEmpty) {
        return null;
      }
      return event.docs.first.get("value");
    });
  }

  Stream<List<String>> getAvailableThirdPartyProviders(
      {required String channelId}) {
    return db
        .collection("channels")
        .doc(channelId)
        .snapshots()
        .map((doc) => (doc.get("thirdParty") ?? {}).keys.toList());
  }
}
