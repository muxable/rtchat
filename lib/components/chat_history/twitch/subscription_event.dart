import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

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
                style: Theme.of(context).textTheme.titleSmall),
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
                style: Theme.of(context).textTheme.titleSmall),
            TextSpan(
                text:
                    " gifted ${model.total} Tier ${model.tier.replaceAll("000", "")} "),
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

  Iterable<InlineSpan> _render(
      BuildContext context, StyleModel styleModel, MessageToken token) sync* {
    final tagStyleStreamer = TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white);
    //for streamermention

    final tagStyle = TextStyle(
        backgroundColor: Theme.of(context).highlightColor); //for usermention

    if (token is TextToken) {
      yield TextSpan(text: token.text);
    } else if (token is EmoteToken) {
      yield WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Tooltip(
              message: token.code,
              preferBelow: false,
              child: Image(
                  height: styleModel.fontSize,
                  image: ResilientNetworkImage(token.url),
                  errorBuilder: (context, error, stackTrace) =>
                      Text(token.code))));
    } else if (token is UserMentionToken) {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final loginChannel = userModel.userChannel?.displayName;
      if (token.username.toLowerCase() == loginChannel?.toLowerCase()) {
        yield TextSpan(
            // wrap tag with nonbreaking spaces
            text: "\u{00A0}@${token.username}\u{00A0}",
            style: tagStyleStreamer);
      } else {
        yield TextSpan(
            // wrap tag with nonbreaking spaces
            text: "\u{00A0}@${token.username}\u{00A0}",
            style: tagStyle);
      }
    } else {
      throw Exception("invalid token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text("Tier ${model.tier.replaceAll("000", "")}"),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              TextSpan(
                  text: model.subscriberUserName,
                  style: Theme.of(context).textTheme.titleSmall),
              const TextSpan(text: " subscribed for "),
              TextSpan(
                  text: model.cumulativeMonths == 1
                      ? "1 month!"
                      : "${model.cumulativeMonths} months!",
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        if (model.text.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Consumer<StyleModel>(builder: (context, styleModel, child) {
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: model.subscriberUserName,
                          style: Theme.of(context).textTheme.titleSmall),
                      const TextSpan(text: ": "),
                      ...model.tokenize().expand((token) {
                        return _render(context, styleModel, token);
                      }),
                    ],
                  ),
                );
              })),
      ]),
    );
  }
}
