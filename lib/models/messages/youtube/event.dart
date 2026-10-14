import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';

/// A paid message: a Super Chat or a Super Sticker.
abstract class YouTubeSuperEventModel extends MessageModel {
  final YouTubeUserModel author;
  final int amountMicros;
  final String currency;

  /// The amount as YouTube formats it, e.g. `$5.00`.
  final String amountDisplayString;

  /// Higher amounts are in higher tiers, starting at 1. The tier picks the
  /// event's color.
  final int tier;

  const YouTubeSuperEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.author,
      required this.amountMicros,
      required this.currency,
      required this.amountDisplayString,
      required this.tier});
}

class YouTubeSuperChatEventModel extends YouTubeSuperEventModel {
  final String? comment;

  const YouTubeSuperChatEventModel(
      {required super.messageId,
      required super.timestamp,
      required super.author,
      required super.amountMicros,
      required super.currency,
      required super.amountDisplayString,
      required super.tier,
      this.comment});
}

class YouTubeSuperStickerEventModel extends YouTubeSuperEventModel {
  final String stickerId;

  /// A description of the sticker, e.g. "Dancing cat".
  final String? altText;

  const YouTubeSuperStickerEventModel(
      {required super.messageId,
      required super.timestamp,
      required super.author,
      required super.amountMicros,
      required super.currency,
      required super.amountDisplayString,
      required super.tier,
      required this.stickerId,
      this.altText});
}

/// A new channel member, or a member upgrading their level.
class YouTubeNewMemberEventModel extends MessageModel {
  final YouTubeUserModel member;
  final String levelName;
  final bool isUpgrade;

  const YouTubeNewMemberEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.member,
      required this.levelName,
      required this.isUpgrade});
}

class YouTubeMemberMilestoneEventModel extends MessageModel {
  final YouTubeUserModel member;
  final String levelName;
  final int months;
  final String? comment;

  const YouTubeMemberMilestoneEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.member,
      required this.levelName,
      required this.months,
      this.comment});
}

/// Someone gifting memberships to other viewers.
class YouTubeMembershipGiftingEventModel extends MessageModel {
  final YouTubeUserModel gifter;
  final int count;
  final String levelName;

  const YouTubeMembershipGiftingEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.gifter,
      required this.count,
      required this.levelName});
}

/// A viewer receiving a gifted membership.
class YouTubeGiftMembershipReceivedEventModel extends MessageModel {
  final YouTubeUserModel recipient;
  final String levelName;
  final String? gifterChannelId;

  const YouTubeGiftMembershipReceivedEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.recipient,
      required this.levelName,
      this.gifterChannelId});
}

/// A gift bought with Jewels.
class YouTubeGiftEventModel extends MessageModel {
  final YouTubeUserModel sender;
  final String giftName;
  final int jewels;
  final String? giftUrl;
  final String? altText;
  final int comboCount;

  const YouTubeGiftEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.sender,
      required this.giftName,
      required this.jewels,
      this.giftUrl,
      this.altText,
      this.comboCount = 1});
}

class YouTubePollOption {
  final String text;
  final int tally;

  const YouTubePollOption({required this.text, required this.tally});
}

class YouTubePollEventModel extends MessageModel {
  final YouTubeUserModel author;
  final String question;
  final List<YouTubePollOption> options;
  final bool isClosed;

  const YouTubePollEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.author,
      required this.question,
      required this.options,
      required this.isClosed});

  int get totalVotes => options.fold(0, (sum, option) => sum + option.tally);

  int get maxVotes =>
      options.fold(0, (max, option) => option.tally > max ? option.tally : max);
}

class YouTubeMembersOnlyModeEventModel extends MessageModel {
  final bool isEnabled;

  const YouTubeMembersOnlyModeEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.isEnabled});
}

class YouTubeChatEndedEventModel extends MessageModel {
  const YouTubeChatEndedEventModel(
      {required super.messageId, required super.timestamp});
}
