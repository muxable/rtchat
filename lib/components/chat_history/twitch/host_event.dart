import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

class TwitchHostEventWidget extends StatelessWidget {
  final TwitchHostEventModel model;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchHostEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(model.from.profilePictureUrl),
      child: Text.rich(TextSpan(
        children: [
          TextSpan(
              text: model.from.displayName,
              style: Theme.of(context).textTheme.titleSmall),
          const TextSpan(text: " is hosting with a party of "),
          TextSpan(
              text: _formatter.format(model.viewers),
              style: Theme.of(context).textTheme.titleSmall),
          const TextSpan(text: "."),
        ],
      )),
    );
  }
}
