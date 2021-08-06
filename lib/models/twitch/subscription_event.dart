import 'package:rtchat/models/message.dart';

class TwitchSubscriptionEventModel extends MessageModel {
  final String subscriberUserName;
  final bool isGift;
  final String tier;

  const TwitchSubscriptionEventModel(
      {required bool pinned,
      required String messageId,
      required this.subscriberUserName,
      required this.isGift,
      required this.tier})
      : super(messageId: messageId, pinned: pinned);
}
