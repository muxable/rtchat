import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

class TwitchSubscriptionEventWidget extends StatelessWidget {
  final TwitchSubscriptionEventModel model;

  const TwitchSubscriptionEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.star,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: model.subscriberUserName,
                style: Theme.of(context).textTheme.subtitle2),
            TextSpan(
                text:
                    " subscribed at Tier ${model.tier.replaceAll("000", "")}."),
          ],
        ),
      ),
    );
  }
}

class TwitchSubscriptionGiftEventWidget extends StatelessWidget {
  final TwitchSubscriptionGiftEventModel model;

  const TwitchSubscriptionGiftEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.star,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: model.gifterUserName,
                style: Theme.of(context).textTheme.subtitle2),
            TextSpan(
                text:
                    " gifted ${model.total} Tier ${model.tier.replaceAll("000", "")}"),
            TextSpan(
                text: model.total > 1 ? "subscriptions. " : "subscription. "),
            TextSpan(
                text: model.cumulativeTotal > 0
                    ? "They've gifted ${model.cumulativeTotal} months in the channel"
                    : ""),
          ],
        ),
      ),
    );
  }
}

class TwitchSubscriptionMessageEventWidget extends StatelessWidget {
  final TwitchSubscriptionMessageEventModel model;

  const TwitchSubscriptionMessageEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.star,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: model.subscriberUserName,
                style: Theme.of(context).textTheme.subtitle2),
            TextSpan(
                text:
                    " subscribed at Tier ${model.tier.replaceAll("000", "")}. They've subscribed for "),
            TextSpan(
                text: "${model.cumulativeMonths} months",
                style: Theme.of(context).textTheme.subtitle2),
            TextSpan(
                text: model.streakMonths > 1
                    ? ", currently on a ${model.streakMonths} month streak!"
                    : "!"),
          ],
        ),
      ),
    );
  }
}
