import 'package:cloud_firestore/cloud_firestore.dart';

class Viewers {
  final List<String> broadcaster;
  final List<String> moderators;
  final List<String> vips;
  final List<String> viewers;

  Viewers({
    required this.broadcaster,
    required this.moderators,
    required this.vips,
    required this.viewers,
  });

  // create a new instance that filters to viewers matching a certain substring.
  Viewers query(String text) {
    if (text.isEmpty) {
      return this;
    }
    return Viewers(
      broadcaster: broadcaster
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      moderators: moderators
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      vips: vips
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      viewers: viewers
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
    );
  }

  // flatten the viewers to a list
  List<String> flatten() {
    return broadcaster + moderators + vips + viewers;
  }
}

class ChatStateAdapter {
  final FirebaseFirestore db;

  ChatStateAdapter._({required this.db});

  static ChatStateAdapter get instance =>
      _instance ??= ChatStateAdapter._(db: FirebaseFirestore.instance);
  static ChatStateAdapter? _instance;

  Stream<Viewers> getViewers({required String channelId}) {
    return db
        .collection('chat-status')
        .where("channelId", isEqualTo: channelId)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .expand((snapshot) sync* {
      if (snapshot.docs.isEmpty) {
        return;
      }
      final doc = snapshot.docs.first.data();
      yield Viewers(
        broadcaster: <String>[...(doc['broadcaster'] ?? [])],
        moderators: <String>[...(doc['moderators'] ?? [])],
        vips: <String>[...(doc['vips'] ?? [])],
        viewers: <String>[...(doc['viewers'] ?? [])],
      );
    });
  }
}
