import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchShoutoutCreateEventWidget extends StatelessWidget {
  final TwitchShoutoutCreateEventModel model;

  const TwitchShoutoutCreateEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.campaign,
      child: StyledText(
        text:
            'Shoutout was given to <b>${model.toBroadcasterUserName}</b> with ${model.viewerCount} viewers',
        tags: {
          'b': StyledTextTag(
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
        },
      ),
    );
  }
}

class TwitchShoutoutReceiveEventWidget extends StatelessWidget {
  final TwitchShoutoutReceiveEventModel model;

  const TwitchShoutoutReceiveEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.campaign,
      child: StyledText(
        text:
            '<b>${model.fromBroadcasterUserName}</b> gave you a shoutout to ${model.viewerCount} viewers',
        tags: {
          'b': StyledTextTag(
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
        },
      ),
    );
  }
}
