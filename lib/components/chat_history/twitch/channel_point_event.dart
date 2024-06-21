import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchChannelPointRedemptionEventWidget extends StatelessWidget {
  final TwitchChannelPointRedemptionEventModel model;

  const TwitchChannelPointRedemptionEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: model.icon,
      child: StyledText(
        text:
            '<b>${model.redeemerUsername}</b> redeemed <b>${model.rewardName}</b> for ${model.rewardCost} points. ${model.userInput ?? ''}',
        tags: {
          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
        },
      ),
    );
  }
}
