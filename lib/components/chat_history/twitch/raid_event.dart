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
              text: AppLocalizations.of(
                context,
              )!.raidEventMessage(model.from.displayName ?? "", model.viewers),
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

class TwitchRaidEventGroupWidget extends StatelessWidget {
  final List<TwitchRaidEventModel> raids;
  final Channel channel;
  final VoidCallback onExpand;

  const TwitchRaidEventGroupWidget({
    super.key,
    required this.raids,
    required this.channel,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<EventSubConfigurationModel, RaidEventConfig>(
      selector: (context, model) => model.raidEventConfig,
      builder: (context, config, child) {
        if (!config.showEvent || raids.isEmpty) {
          return const SizedBox.shrink();
        }

        final first = raids.first;
        final localizations = AppLocalizations.of(context)!;
        final style = Theme.of(context).textTheme.titleSmall;

        final summary =
            '${localizations.raidEventMessage(first.from.displayName ?? '', first.viewers)} (+${raids.length - 1} more raids)';

        return InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topLeft,
            child: DecoratedEventWidget.avatars(
              avatars: raids
                  .take(3)
                  .map(
                    (raid) =>
                        ResilientNetworkImage(raid.from.profilePictureUrl),
                  ),
              child: StyledText(
                text: summary,
                tags: {'b': StyledTextTag(style: style)},
              ),
            ),
          ),
        );
      },
    );
  }
}
