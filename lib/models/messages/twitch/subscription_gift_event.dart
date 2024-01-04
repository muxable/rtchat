import 'package:rtchat/models/messages/message.dart';

class TwitchSubscriptionGiftEventModel extends MessageModel {
  final String gifterUserName;
  final String tier;
  final int total;
  final int cumulativeTotal;

  const TwitchSubscriptionGiftEventModel(
      {required super.timestamp,
      required super.messageId,
      required this.gifterUserName,
      required this.tier,
      required this.total,
      required this.cumulativeTotal});
}
