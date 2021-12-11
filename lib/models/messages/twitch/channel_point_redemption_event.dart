import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';

enum TwitchChannelPointRedemptionStatus {
  fulfilled,
  canceled,
  unfulfilled,
  unknown
}

extension TwitchChannelPointRedemptionStatusParser
    on TwitchChannelPointRedemptionStatus {
  static TwitchChannelPointRedemptionStatus toEnum(String value) {
    switch (value) {
      case 'fulfilled':
        return TwitchChannelPointRedemptionStatus.fulfilled;
      case 'canceled':
        return TwitchChannelPointRedemptionStatus.canceled;
      case 'unfulfilled':
        return TwitchChannelPointRedemptionStatus.unfulfilled;
      default:
        return TwitchChannelPointRedemptionStatus.unknown;
    }
  }
}

class TwitchChannelPointRedemptionEventModel extends MessageModel {
  final String redeemerUsername;
  final TwitchChannelPointRedemptionStatus status;
  final String rewardName;
  final int rewardCost;
  final String? userInput;

  const TwitchChannelPointRedemptionEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.redeemerUsername,
      required this.status,
      required this.rewardName,
      required this.rewardCost,
      required this.userInput})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchChannelPointRedemptionEventModel fromDocumentData(
      Map<String, dynamic> data) {
    return TwitchChannelPointRedemptionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.point-redemption-${data['event']['id']}",
        redeemerUsername: data['event']['user_name'],
        status: TwitchChannelPointRedemptionStatusParser.toEnum(
            data['event']['status']),
        rewardName: data['event']['reward']['title'],
        rewardCost: data['event']['reward']['cost'],
        userInput: data['event']['user_input']);
  }

  IconData get icon {
    switch (status) {
      case TwitchChannelPointRedemptionStatus.fulfilled:
        return Icons.done;
      case TwitchChannelPointRedemptionStatus.canceled:
        return Icons.close;
      case TwitchChannelPointRedemptionStatus.unfulfilled:
        return Icons.timer;
      case TwitchChannelPointRedemptionStatus.unknown:
        return Icons.help;
      default:
        return Icons.done;
    }
  }
}
