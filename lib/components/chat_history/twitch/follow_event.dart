import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/network.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class TwitchFollowEventWidget extends StatelessWidget {
  final TwitchFollowEventModel model;

  const TwitchFollowEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventSubConfigurationModel =
        Provider.of<EventSubConfigurationModel>(context, listen: false);
    if (!eventSubConfigurationModel.followEventConfig.showEvent) {
      return Container();
    }
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
