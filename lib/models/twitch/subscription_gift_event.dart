import 'package:rtchat/models/message.dart';

class TwitchSubscriptionGiftEventModel extends MessageModel {
  final String gifterUserName;
  final String tier;
  final int total;

  const TwitchSubscriptionGiftEventModel(
      {required bool pinned,
      required String messageId,
      required this.gifterUserName,
      required this.tier,
      required this.total})
      : super(messageId: messageId, pinned: pinned);
}
