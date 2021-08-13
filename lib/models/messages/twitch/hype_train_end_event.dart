import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rtchat/models/messages/message.dart';

class TwitchHypeTrainEndEventModel extends MessageModel {
  final int level;
  final int total;
  final bool wasSuccessful;

  const TwitchHypeTrainEndEventModel(
      {required bool pinned,
      required String messageId,
      required this.level,
      required this.total,
      required this.wasSuccessful})
      : super(messageId: messageId, pinned: pinned);

  static TwitchHypeTrainEndEventModel fromDocument(
      {required DocumentSnapshot<Map<String, dynamic>> document,
      bool wasSuccessful = false,
      bool pinned = true}) {
    final data = document.data();
    return TwitchHypeTrainEndEventModel(
        pinned: pinned,
        messageId: data!['event']['id'],
        level: data['event']['level'],
        total: data['event']['total'],
        wasSuccessful: wasSuccessful);
  }
}
