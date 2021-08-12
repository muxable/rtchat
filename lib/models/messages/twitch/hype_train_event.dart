import 'package:rtchat/models/messages/message.dart';

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
}
