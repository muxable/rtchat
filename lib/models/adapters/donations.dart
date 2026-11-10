import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/accounts.dart';

class StreamlabsConfig {
  final String? currency;

  StreamlabsConfig({this.currency});
}

class StreamElementsConfig {
  StreamElementsConfig();
}

class RealtimeKitConfig {
  final String apiKey;

  RealtimeKitConfig({required this.apiKey});
}

class DonationsAdapter {
  final FirebaseFirestore db;
  final Api api;

  DonationsAdapter._({required this.db, required this.api});

  /// Reads and writes [account]'s own connections, which are owner-only.
  static DonationsAdapter forAccount(Account account) =>
      _forApp[account.app.name] ??= DonationsAdapter._(
        db: FirebaseFirestore.instanceFor(app: account.app),
        api: Api.forAccount(account),
      );
  static final Map<String, DonationsAdapter> _forApp = {};

  Stream<String?> forRealtimeChatAddress({required String userId}) {
    return db
        .collection("realtimecash")
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.get("address") : null);
  }

  Future<void> setRealtimeCashAddress({required String address}) {
    return api.callable("setRealTimeCashAddress")({"address": address});
  }

  Stream<RealtimeKitConfig?> forRealtimeKitConfig({required String userId}) {
    return db.collection("realtimekit").doc(userId).snapshots().map((doc) {
      final apiKey = doc.data()?["apiKey"] as String?;
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return RealtimeKitConfig(apiKey: apiKey);
    });
  }

  Future<void> setRealtimeKitApiKey({required String apiKey}) {
    return api.callable("setRealtimeKitApiKey")({"apiKey": apiKey});
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

  Stream<StreamElementsConfig?> forStreamElementsConfig({
    required String userId,
  }) {
    return db.collection("streamelements").doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data["token"] == null) {
        return null;
      }
      return StreamElementsConfig();
    });
  }
}
