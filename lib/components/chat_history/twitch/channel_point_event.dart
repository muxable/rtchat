import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/style.dart';

class TwitchChannelPointRedemptionEventWidget extends StatelessWidget {
  final TwitchChannelPointRedemptionEventModel model;

  const TwitchChannelPointRedemptionEventWidget(this.model, {Key? key})
      : super(key: key);

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
                  Icon(defineIcon(), size: styleModel.fontSize * 1.5)),
          const SizedBox(width: 12),
          Expanded(
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
          )
        ]),
      ),
    );
  }

  IconData defineIcon() {
    switch (model.status) {
      case "fulfilled":
        return Icons.done;
      case "cancelled":
        return Icons.close;
      case "unfulfilled":
        return Icons.timer;
      case "unknown":
        return Icons.help;
      default:
        return Icons.done;
    }
  }
}
