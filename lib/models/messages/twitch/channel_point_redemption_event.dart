import 'package:rtchat/models/messages/message.dart';

class TwitchChannelPointRedemptionEventModel extends MessageModel {
  final String redeemerUsername;
  final String status;
  final String rewardName;
  final int rewardCost;

  const TwitchChannelPointRedemptionEventModel(
      {required bool pinned,
      required String messageId,
      required this.redeemerUsername,
      required this.status,
      required this.rewardName,
      required this.rewardCost})
      : super(messageId: messageId, pinned: pinned);
}
