import 'package:rtchat/models/messages/message.dart';

class TwitchSubscriptionMessageEventModel extends MessageModel {
  final String subscriberUserName;
  final String tier;
  final int cumulativeMonths;
  final int durationMonths;
  final int streakMonths;
  final String text;

  const TwitchSubscriptionMessageEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.subscriberUserName,
      required this.tier,
      required this.cumulativeMonths,
      required this.durationMonths,
      required this.streakMonths,
      required this.text})
      : super(messageId: messageId, timestamp: timestamp);
}
