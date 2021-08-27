import 'package:rtchat/models/messages/message.dart';

class TwitchSubscriptionEventModel extends MessageModel {
  final String subscriberUserName;
  final bool isGift;
  final String tier;

  const TwitchSubscriptionEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.subscriberUserName,
      required this.isGift,
      required this.tier})
      : super(messageId: messageId, timestamp: timestamp);
}
