import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchRaidEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: NetworkImageWithRetry(model.from.profilePictureUrl),
      child: Text.rich(TextSpan(
        children: [
          TextSpan(
              text: model.from.displayName,
              style: Theme.of(context).textTheme.subtitle2),
          const TextSpan(text: " is raiding with a party of "),
          TextSpan(
              text: _formatter.format(model.viewers),
              style: Theme.of(context).textTheme.subtitle2),
          const TextSpan(text: "."),
        ],
      )),
    );
  }
}
