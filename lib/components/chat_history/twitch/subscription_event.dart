import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';

class TwitchSubscriptionEventWidget extends StatelessWidget {
  final TwitchSubscriptionEventModel model;

  const TwitchSubscriptionEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Consumer<StyleModel>(
              builder: (context, styleModel, child) =>
                  Icon(Icons.star, size: styleModel.fontSize * 1.5)),
          const SizedBox(width: 12),
          Expanded(
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
          )
        ]),
      ),
    );
  }
}
