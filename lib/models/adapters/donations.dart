import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StreamlabsConfig {
  final String? currency;

  StreamlabsConfig({this.currency});
}

class DonationsAdapter {
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  DonationsAdapter._({required this.db, required this.functions});

  static DonationsAdapter get instance => _instance ??= DonationsAdapter._(
      db: FirebaseFirestore.instance, functions: FirebaseFunctions.instance);
  static DonationsAdapter? _instance;

  Stream<String?> forRealtimeChatAddress({required String userId}) {
    return db
        .collection("realtimecash")
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.get("address") : null);
  }

  Future<void> setRealtimeCashAddress({required String address}) {
    return functions
        .httpsCallable("setRealTimeCashAddress")({"address": address});
  }

  Stream<StreamlabsConfig?> forStreamlabsConfig({required String userId}) {
    return db.collection("streamlabs").doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data["token"] == null) {
        return null;
      }
      return StreamlabsConfig(currency: data["currency"]);
    });
  }
}
