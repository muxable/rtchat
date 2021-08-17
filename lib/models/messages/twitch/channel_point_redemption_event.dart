import 'package:rtchat/models/messages/message.dart';

class TwitchChannelPointRedemptionEventModel extends MessageModel {
  final String redeemerUsername;
  final String status;
  final String rewardName;
  final int rewardCost;
  final String? userInput;

  const TwitchChannelPointRedemptionEventModel(
      {required bool pinned,
      required String messageId,
      required this.redeemerUsername,
      required this.status,
      required this.rewardName,
      required this.rewardCost,
      required this.userInput})
      : super(messageId: messageId, pinned: pinned);

  static TwitchChannelPointRedemptionEventModel fromDocumentData(
      {required Map<String, dynamic>? data, bool pinned = false}) {
    return TwitchChannelPointRedemptionEventModel(
        pinned: pinned,
        messageId: "channel.point-redemption-${data!['event']['id']}",
        redeemerUsername: data['event']['user_name'],
        status: data['event']['status'],
        rewardName: data['event']['reward']['title'],
        rewardCost: data['event']['reward']['cost'],
        userInput: data['event']['user_input']);
  }
}
