import 'package:cloud_firestore/cloud_firestore.dart';

class StreamlabsConfig {
  final String? currency;

  StreamlabsConfig({this.currency});
}

class DonationsAdapter {
  final FirebaseFirestore db;

  DonationsAdapter._({required this.db});

  static DonationsAdapter get instance =>
      _instance ??= DonationsAdapter._(db: FirebaseFirestore.instance);
  static DonationsAdapter? _instance;

  Stream<String?> forRealtimeChatAddress({required String userId}) {
    return db
        .collection("realtimechat")
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.get("address") : null);
  }

  Stream<StreamlabsConfig?> forStreamlabsConfig({required String userId}) {
    return db.collection("streamlabs").doc(userId).snapshots().map((doc) =>
        doc.exists ? StreamlabsConfig(currency: doc.get("currency")) : null);
  }
}
