import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:styled_text/styled_text.dart';

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
            return StyledText(
                text: AppLocalizations.of(context)!
                    .followingEvent(model.followers.first.display),
                tags: {
                  'bold': StyledTextTag(
                      style: Theme.of(context).textTheme.titleSmall),
                });
          case 2:
            // return x and y are following you.
            return StyledText(
                text: AppLocalizations.of(context)!.followingEvent2(
                    model.followers.first.display,
                    model.followers.last.display),
                tags: {
                  'bold': StyledTextTag(
                      style: Theme.of(context).textTheme.titleSmall),
                });
          default:
            // return x, y, and n others are following you.
            return StyledText(
                text: AppLocalizations.of(context)!.followingEvent3(
                    model.followers.first.display,
                    model.followers.last.display,
                    model.followers.length - 2),
                tags: {
                  'bold': StyledTextTag(
                      style: Theme.of(context).textTheme.titleSmall),
                });
        }
      })),
    );
  }
}
