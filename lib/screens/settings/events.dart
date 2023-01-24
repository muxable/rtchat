import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/channel_point_event.dart';
import 'package:rtchat/components/chat_history/twitch/cheer_event.dart';
import 'package:rtchat/components/chat_history/twitch/follow_event.dart';
import 'package:rtchat/components/chat_history/twitch/host_event.dart';
import 'package:rtchat/components/chat_history/twitch/hype_train_event.dart';
import 'package:rtchat/components/chat_history/twitch/poll_event.dart';
import 'package:rtchat/components/chat_history/twitch/prediction_event.dart';
import 'package:rtchat/components/chat_history/twitch/raid_event.dart';
import 'package:rtchat/components/chat_history/twitch/raiding_event.dart';
import 'package:rtchat/components/chat_history/twitch/subscription_event.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        final dateTime = DateTime.now();
        return Consumer<EventSubConfigurationModel>(
            builder: (context, eventSubConfig, child) {
          return ListView(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StyleModelTheme(
                    child: TwitchFollowEventWidget(TwitchFollowEventModel(
                  followers: [
                    const TwitchUserModel(
                        userId: '158394109',
                        login: 'muxfd',
                        displayName: 'muxfd')
                  ],
                  messageId: '',
                  timestamp: DateTime.now(),
                )))),
            EventConfigListTile(
              title: const Text('Follow event config'),
              subtitle: const Text('Customize your follow event'),
              routeName: '/settings/events/follow',
              child: Switch.adaptive(
                value: eventSubConfig.followEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setFollowEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchSubscriptionEventWidget(
                        TwitchSubscriptionEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  isGift: false,
                  subscriberUserName: 'muxfd',
                  tier: '1000',
                )))),
            EventConfigListTile(
              title: const Text('Subscribe event config'),
              subtitle: const Text('Customize your subscription event'),
              routeName: '/settings/events/subscription',
              child: Switch.adaptive(
                value: eventSubConfig.subscriptionEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setSubscriptionEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchCheerEventWidget(TwitchCheerEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  bits: 722,
                  cheerMessage: 'You\'re the best streamer!',
                  giverName: 'muxfd',
                  isAnonymous: false,
                )))),
            EventConfigListTile(
              title: const Text('Cheer event config'),
              subtitle: const Text('Customize your cheer event'),
              routeName: '/settings/events/cheer',
              child: Switch.adaptive(
                value: eventSubConfig.cheerEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setCheerEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchRaidEventWidget(
                        TwitchRaidEventModel(
                          messageId: '',
                          timestamp: DateTime.now(),
                          from: const TwitchUserModel(
                              userId: '158394109',
                              login: 'muxfd',
                              displayName: 'muxfd'),
                          viewers: 4,
                        ),
                        channel: Channel(
                          "twitch",
                          "muxfd",
                          "muxfd",
                        )))),
            EventConfigListTile(
              title: const Text('Raid event config'),
              subtitle: const Text('Customize your raid event'),
              routeName: '/settings/events/raid',
              child: Switch.adaptive(
                value: eventSubConfig.raidEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setRaidEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchHostEventWidget(TwitchHostEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  from: const TwitchUserModel(
                      userId: '158394109',
                      login: 'muxfd',
                      displayName: 'muxfd'),
                  viewers: 5,
                )))),
            EventConfigListTile(
              title: const Text('Host event config'),
              subtitle: const Text('Customize your host event'),
              routeName: '/settings/events/host',
              child: Switch.adaptive(
                value: eventSubConfig.hostEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setHostEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchHypeTrainEventWidget(TwitchHypeTrainEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  goal: 500,
                  level: 2,
                  progress: 75,
                  total: 88,
                  startTimestamp: DateTime(2021),
                  endTimestamp: DateTime(2021),
                )))),
            EventConfigListTile(
              title: const Text('Hypetrain event config'),
              subtitle: const Text('Customize your hypetrain event'),
              routeName: '/settings/events/hypetrain',
              child: Switch.adaptive(
                value: eventSubConfig.hypetrainEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setHypetrainEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchPollEventWidget(TwitchPollEventModel(
                        messageId: '',
                        timestamp: DateTime.now(),
                        choices: const [
                          PollChoiceModel(
                              bitVotes: 3,
                              channelPointVotes: 75,
                              id: 'yes',
                              title: 'yes',
                              votes: 10),
                          PollChoiceModel(
                              bitVotes: 74,
                              channelPointVotes: 125,
                              id: 'no',
                              title: 'no',
                              votes: 60)
                        ],
                        isCompleted: false,
                        pollTitle: 'Have you streamed today?',
                        startTimestamp: DateTime(2021),
                        endTimestamp: DateTime(2021),
                        status: 'placeholder')))),
            EventConfigListTile(
              title: const Text('Poll event config'),
              subtitle: const Text('Customize your poll event'),
              routeName: '/settings/events/poll',
              child: Switch.adaptive(
                value: eventSubConfig.pollEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setPollEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchPredictionEventWidget(
                        TwitchPredictionEventModel(
                            timestamp: dateTime,
                            messageId: '',
                            title: 'Coin flip prediction',
                            endTime: dateTime,
                            status: 'in_progress',
                            outcomes: [
                      TwitchPredictionOutcomeModel(
                          'outcome1', 50, 'pink', 'Heads'),
                      TwitchPredictionOutcomeModel(
                          'outcome2', 100, 'blue', 'Tails')
                    ])))),
            EventConfigListTile(
              title: const Text('Prediction event config'),
              subtitle: const Text('Customize your prediction event'),
              routeName: '/settings/events/prediction',
              child: Switch.adaptive(
                value: eventSubConfig.predictionEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setPredictionEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchChannelPointRedemptionEventWidget(
                        TwitchChannelPointRedemptionEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  redeemerUsername: 'muxfd',
                  status: TwitchChannelPointRedemptionStatus.fulfilled,
                  rewardName: 'do a backflip',
                  rewardCost: 1000,
                  userInput: 'Infront of Topaz!',
                )))),
            EventConfigListTile(
              title: const Text('Channel point redemption event config'),
              subtitle:
                  const Text('Customize your channel point redemption event'),
              routeName: '/settings/events/channel-point',
              child: Switch.adaptive(
                value:
                    eventSubConfig.channelPointRedemptionEventConfig.showEvent,
                onChanged: (value) => eventSubConfig
                    .setChannelPointRedemptionEventShowable(value),
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchRaidingEventWidget(TwitchRaidingEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  duration: const Duration(seconds: 90),
                  targetUser: const TwitchUserModel(
                      userId: '158394109',
                      login: 'muxfd',
                      displayName: 'muxfd'),
                )))),
            EventConfigListTile(
              title: const Text('Outgoing raid event config'),
              subtitle: const Text('Customize your outgoing raid event'),
              routeName: '/settings/events/raiding',
              child: Switch.adaptive(
                value: eventSubConfig.raidingEventConfig.showEvent,
                onChanged: (value) =>
                    eventSubConfig.setRaidingEventShowable(value),
              ),
            ),
          ]);
        });
      }),
    );
  }
}

class EventConfigListTile extends StatelessWidget {
  final Text title;
  final Text subtitle;
  final String routeName;
  final Widget child;

  const EventConfigListTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.routeName,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const VerticalDivider(
            thickness: 2.0,
            indent: 8.0,
            endIndent: 8.0,
          ),
          child,
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
