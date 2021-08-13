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
}
