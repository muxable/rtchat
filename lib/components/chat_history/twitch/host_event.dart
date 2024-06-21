import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchHostEventWidget extends StatelessWidget {
  final TwitchHostEventModel model;

  const TwitchHostEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(model.from.profilePictureUrl),
      child: StyledText(
        text:
            '<b>${model.from.displayName}</b> is hosting with a party of <b>${model.viewers}</b>',
        tags: {
          'b': StyledTextTag(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        },
      ),
    );
  }
}
