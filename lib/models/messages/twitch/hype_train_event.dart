import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rxdart/rxdart.dart';

class TwitchHypeTrainEventModel extends MessageModel {
  final int level;
  final int progress;
  final int goal;
  final int total;

  const TwitchHypeTrainEventModel(
      {required bool pinned,
      required String messageId,
      required this.level,
      required this.progress,
      required this.goal,
      required this.total})
      : super(messageId: messageId, pinned: pinned);

  static TwitchHypeTrainEventModel fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    return TwitchHypeTrainEventModel(
        pinned: true,
        messageId: "train${data!['event']['id']}",
        level: data['event']['level'] ?? 1,
        progress: data['event']['progress'],
        goal: data['event']['goal'],
        total: data['event']['total']);
  }

  TwitchHypeTrainEventModel withProgress(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final level = data!['event']['level'];
    final total = data['event']['total'];

    if (this.level > level || this.total > total) {
      return this;
    }

    return fromDocument(document);
  }
}
