import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';

class TwitchChannelPointRedemptionEventWidget extends StatelessWidget {
  final TwitchChannelPointRedemptionEventModel model;

  const TwitchChannelPointRedemptionEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: model.icon,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: model.redeemerUsername,
                style: Theme.of(context).textTheme.titleSmall),
            const TextSpan(text: " redeemed "),
            TextSpan(
                text: "${model.rewardName} ",
                style: Theme.of(context).textTheme.titleSmall),
            TextSpan(
                text:
                    "for ${model.rewardCost} points. ${model.userInput ?? ''}"),
          ],
        ),
      ),
    );
  }
}
