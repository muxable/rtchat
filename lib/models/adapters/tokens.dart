import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class TokensAdapter {
  final FirebaseFirestore db;

  TokensAdapter._({required this.db});

  static TokensAdapter get instance =>
      _instance ??= TokensAdapter._(db: FirebaseFirestore.instance);
  static TokensAdapter? _instance;

  Future<String?> getAccessToken(
      {required String userId, required String provider}) async {
    final doc = await db.collection("tokens").doc(userId).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null || !data.containsKey(provider)) {
      return null;
    }
    return jsonDecode(data[provider])['access_token'];
  }
}
