import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

class TwitchFollowEventWidget extends StatelessWidget {
  final TwitchFollowEventModel model;

  const TwitchFollowEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatars(
      avatars: model.followers
          .sublist(0, min(3, model.followers.length))
          .map((follower) => ResilientNetworkImage(follower.profilePictureUrl)),
      child: Builder(builder: ((context) {
        switch (model.followers.length) {
          case 1:
            return Text.rich(TextSpan(children: [
              TextSpan(
                  text: model.followers.first.display,
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(text: " is following you.")
            ]));
          case 2:
            // return x and y are following you.
            return Text.rich(TextSpan(children: [
              TextSpan(
                  text: model.followers.first.display,
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(text: " and "),
              TextSpan(
                  text: model.followers.last.display,
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(text: " are following you.")
            ]));
          default:
            // return x, y, and n others are following you.
            return Text.rich(TextSpan(children: [
              TextSpan(
                  text: model.followers.first.display,
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(text: ", "),
              TextSpan(
                  text: model.followers.last.display,
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(
                  text:
                      ", and ${model.followers.length - 2} others are following you.")
            ]));
        }
      })),
    );
  }
}
