import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';

class TwitchShoutoutCreateEventWidget extends StatelessWidget {
  final TwitchShoutoutCreateEventModel model;

  const TwitchShoutoutCreateEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.auto_awesome,
      child: Builder(builder: (context) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: "Shoutout was given to ",
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(
                text: model.toBroadcasterUserName,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Colors.purpleAccent),
              ),
              TextSpan(
                  text: " with ${model.viewerCount} viewers",
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        );
      }),
    );
  }
}

class TwitchShoutoutReceiveEventWidget extends StatelessWidget {
  final TwitchShoutoutReceiveEventModel model;

  const TwitchShoutoutReceiveEventWidget(this.model, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.auto_awesome,
      child: Builder(builder: (context) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: model.fromBroadcasterUserName,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Colors.purpleAccent),
              ),
              TextSpan(
                  text: " gave you a shoutout",
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(
                  text: " to ${model.viewerCount} viewers",
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        );
      }),
    );
  }
}
