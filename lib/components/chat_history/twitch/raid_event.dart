import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/user.dart';
import 'package:styled_text/styled_text.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;
  final Channel channel;

  const TwitchRaidEventWidget(this.model, {super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(model.from.profilePictureUrl),
      child: Row(
        children: [
          Expanded(
            child: StyledText(
              text: AppLocalizations.of(context)!.raidEventMessage(
                htmlEscape.convert(model.from.displayName ?? ""),
                model.viewers,
              ),
              tags: {
                'b': StyledTextTag(
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              },
            ),
          ),
          Consumer<EventSubConfigurationModel>(
            builder: (context, eventSubConfigurationModel, child) {
              // shoutouts are sent as the account on the channel's provider.
              final account = Provider.of<UserModel>(
                context,
                listen: false,
              ).accountOn(channel.provider);
              if (!eventSubConfigurationModel
                      .raidEventConfig
                      .enableShoutoutButton ||
                  account == null) {
                return Container();
              }
              return GestureDetector(
                child: Text.rich(
                  TextSpan(
                    text: AppLocalizations.of(context)!.shoutout,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).buttonTheme.colorScheme?.primary,
                    ),
                  ),
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ActionsAdapter.forAccount(
                      account,
                    ).shoutout(channel, model.from.userId);
                  } on FirebaseFunctionsException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.message ?? e.code)),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
