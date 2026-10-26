import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/l10n/app_localizations.dart';
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
            model.userInput != null
                ? AppLocalizations.of(
                  context,
                )!.channelPointRedemptionWithUserInput(
                  htmlEscape.convert(model.redeemerUsername),
                  htmlEscape.convert(model.rewardName),
                  model.rewardCost,
                  htmlEscape.convert(model.userInput!),
                )
                : AppLocalizations.of(
                  context,
                )!.channelPointRedemptionWithoutUserInput(
                  htmlEscape.convert(model.redeemerUsername),
                  htmlEscape.convert(model.rewardName),
                  model.rewardCost,
                ),
        tags: {
          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
        },
      ),
    );
  }
}
