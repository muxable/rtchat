import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/message.dart';

class KickFollowEventModel extends MessageModel {
  final KickUserModel follower;

  const KickFollowEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.follower});
}

/// A new subscription or a renewal. [months] is how long the subscriber has
/// been subscribed.
class KickSubscriptionEventModel extends MessageModel {
  final KickUserModel subscriber;
  final int months;
  final bool isRenewal;

  const KickSubscriptionEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.subscriber,
      required this.months,
      required this.isRenewal});
}

class KickGiftedSubscriptionsEventModel extends MessageModel {
  /// Null for anonymous gifts.
  final KickUserModel? gifter;
  final List<KickUserModel> giftees;

  const KickGiftedSubscriptionsEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.gifter,
      required this.giftees});
}

/// Kicks, Kick's virtual currency, sent to the broadcaster.
class KicksGiftedEventModel extends MessageModel {
  final KickUserModel sender;
  final int amount;
  final String giftName;
  final String? message;

  const KicksGiftedEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.sender,
      required this.amount,
      required this.giftName,
      this.message});
}

class KickRewardRedemptionEventModel extends MessageModel {
  final KickUserModel redeemer;
  final String rewardTitle;
  final int cost;
  final String? userInput;
  final String status;

  const KickRewardRedemptionEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.redeemer,
      required this.rewardTitle,
      required this.cost,
      required this.status,
      this.userInput});
}
