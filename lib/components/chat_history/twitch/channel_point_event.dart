import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
                style: Theme.of(context).textTheme.subtitle2),
            TextSpan(
                text:
                    " redeemed ${model.rewardName} for ${model.rewardCost} points. ${model.userInput ?? ''}"),
          ],
        ),
      ),
    );
  }
}
