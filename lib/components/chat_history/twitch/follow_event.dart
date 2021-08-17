import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/network.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

class TwitchFollowEventWidget extends StatelessWidget {
  final TwitchFollowEventModel model;

  const TwitchFollowEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: NetworkImageWithRetry(model.follower.profilePictureUrl),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: model.follower.display,
                style: Theme.of(context).textTheme.subtitle2),
            const TextSpan(text: " is following you."),
          ],
        ),
      ),
    );
  }
}
