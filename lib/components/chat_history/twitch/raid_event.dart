import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:styled_text/styled_text.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;
  final Channel channel;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchRaidEventWidget(this.model, {super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(model.from.profilePictureUrl),
      child: Row(children: [
        Expanded(
          child: StyledText(
            text: '<b>${model.from.displayName}</b> is raiding with a party of ${_formatter.format(model.viewers)}',
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          ),
        ),
        Consumer<EventSubConfigurationModel>(
            builder: (context, eventSubConfigurationModel, child) {
          if (!eventSubConfigurationModel
              .raidEventConfig.enableShoutoutButton) {
            return Container();
          }
          return GestureDetector(
              child: Text.rich(TextSpan(
                  text: "Shoutout",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color:
                          Theme.of(context).buttonTheme.colorScheme?.primary))),
              onTap: () {
                ActionsAdapter.instance
                    .send(channel, "/shoutout ${model.from.login}");
              });
        }),
      ]),
    );
  }
}
