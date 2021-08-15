import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

class TwitchSubscriptionMessageEventWidget extends StatelessWidget {
  final TwitchSubscriptionMessageEventModel model;

  const TwitchSubscriptionMessageEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var boldStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);
      return Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 4,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
          child: Row(children: [
            Icon(Icons.star, size: styleModel.fontSize * 1.5),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: model.subscriberUserName, style: boldStyle),
                    TextSpan(
                        text:
                            " subscribed at Tier ${model.tier.replaceAll("000", "")}. They've subscribed for ",
                        style: baseStyle),
                    TextSpan(
                        text: "${model.cumulativeMonths} months",
                        style: boldStyle),
                    TextSpan(
                        text: model.streakMonths > 1
                            ? ", currently on a ${model.streakMonths} month streak!"
                            : "!",
                        style: baseStyle),
                  ],
                ),
              ),
            )
          ]),
        ),
      );
    });
  }
}
