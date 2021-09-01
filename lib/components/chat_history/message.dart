import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/stream_state_event.dart';
import 'package:rtchat/components/chat_history/timeout_dialog.dart';
import 'package:rtchat/components/chat_history/twitch/channel_point_event.dart';
import 'package:rtchat/components/chat_history/twitch/cheer_event.dart';
import 'package:rtchat/components/chat_history/twitch/follow_event.dart';
import 'package:rtchat/components/chat_history/twitch/hype_train_event.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/components/chat_history/twitch/poll_event.dart';
import 'package:rtchat/components/chat_history/twitch/prediction_event.dart';
import 'package:rtchat/components/chat_history/twitch/raid_event.dart';
import 'package:rtchat/components/chat_history/twitch/subscription_event.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/user.dart';

class ChatHistoryMessage extends StatelessWidget {
  final MessageModel message;

  const ChatHistoryMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = message;
    final enableInlineEvents =
        RemoteConfig.instance.getBool('inline_events_enabled');
    if (m is TwitchMessageModel) {
      return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        final child = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TwitchMessageWidget(m),
        );
        if (layoutModel.isInteractionLockable && layoutModel.locked) {
          return child;
        }
        final userModel = Provider.of<UserModel>(context, listen: false);
        final loginChannel = userModel.userChannel!.channelId;
        final viewingChannel = m.channelId.split(':')[1];

        if (loginChannel != viewingChannel) {
          return child;
        }

        return InkWell(
            onLongPress: () async {
              var showTimeoutDialog = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: ListView(shrinkWrap: true, children: [
                        ListTile(
                            title: const Text('Delete Message'),
                            onTap: () {
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              ActionsAdapter.instance.delete(
                                  channelsModel.subscribedChannels.first,
                                  m.messageId);
                              Navigator.pop(context);
                            }),
                        ListTile(
                            title: Text('Timeout ${m.author.displayName}'),
                            onTap: () {
                              Navigator.pop(context, true);
                            }),
                        ListTile(
                            title: Text('Ban ${m.author.displayName}'),
                            onTap: () {
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              ActionsAdapter.instance.ban(
                                  channelsModel.subscribedChannels.first,
                                  m.author.login,
                                  "banned by streamer");
                              Navigator.pop(context);
                            }),
                        ListTile(
                            title: Text('Unban ${m.author.displayName}'),
                            onTap: () {
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              ActionsAdapter.instance.unban(
                                  channelsModel.subscribedChannels.first,
                                  m.author.login);
                              Navigator.pop(context);
                            }),
                      ]),
                    );
                  });
              if (showTimeoutDialog == true) {
                await showDialog(
                    context: context,
                    builder: (context) {
                      return TimeoutDialog(
                          title: "Timeout ${m.author.displayName}",
                          onPressed: (duration) {
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            ActionsAdapter.instance.timeout(
                                channelsModel.subscribedChannels.first,
                                m.author.login,
                                "timed out by streamer",
                                duration);
                            Navigator.pop(context);
                          });
                    });
              }
            },
            child: child);
      });
    } else if (m is TwitchRaidEventModel) {
      return Selector<EventSubConfigurationModel, RaidEventConfig>(
        selector: (_, model) => model.raidEventConfig,
        builder: (_, config, __) =>
            config.showEvent ? TwitchRaidEventWidget(m) : Container(),
      );
    } else if (m is TwitchSubscriptionEventModel) {
      return Selector<EventSubConfigurationModel, SubscriptionEventConfig>(
        selector: (_, model) => model.subscriptionEventConfig,
        builder: (_, config, __) =>
            config.showEvent || (config.showIndividualGifts && m.isGift)
                ? TwitchSubscriptionEventWidget(m)
                : Container(),
      );
    } else if (m is TwitchSubscriptionGiftEventModel) {
      return Selector<EventSubConfigurationModel, SubscriptionEventConfig>(
        selector: (_, model) => model.subscriptionEventConfig,
        builder: (_, config, __) => config.showEvent
            ? TwitchSubscriptionGiftEventWidget(m)
            : Container(),
      );
    } else if (m is TwitchSubscriptionMessageEventModel) {
      return Selector<EventSubConfigurationModel, SubscriptionEventConfig>(
        selector: (_, model) => model.subscriptionEventConfig,
        builder: (_, config, __) => config.showEvent
            ? TwitchSubscriptionMessageEventWidget(m)
            : Container(),
      );
    } else if (m is StreamStateEventModel) {
      return StreamStateEventWidget(m);
    } else if (m is TwitchFollowEventModel) {
      return Selector<EventSubConfigurationModel, FollowEventConfig>(
        selector: (_, model) => model.followEventConfig,
        builder: (_, config, __) =>
            config.showEvent ? TwitchFollowEventWidget(m) : Container(),
      );
    } else if (m is TwitchCheerEventModel) {
      return Selector<EventSubConfigurationModel, CheerEventConfig>(
        selector: (_, model) => model.cheerEventConfig,
        builder: (_, config, __) =>
            config.showEvent ? TwitchCheerEventWidget(m) : Container(),
      );
    } else if (m is TwitchPollEventModel) {
      return Selector<EventSubConfigurationModel, PollEventConfig>(
        selector: (_, model) => model.pollEventConfig,
        builder: (_, config, __) =>
            config.showEvent ? TwitchPollEventWidget(m) : Container(),
      );
    } else if (m is TwitchChannelPointRedemptionEventModel) {
      return enableInlineEvents
          ? TwitchChannelPointRedemptionEventWidget(m)
          : Container();
    } else if (m is TwitchHypeTrainEventModel) {
      return enableInlineEvents ? TwitchHypeTrainEventWidget(m) : Container();
    } else if (m is TwitchPredictionEventModel) {
      return enableInlineEvents ? TwitchPredictionEventWidget(m) : Container();
    } else {
      throw AssertionError("invalid message type");
    }
  }
}
