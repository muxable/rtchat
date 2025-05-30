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
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.eventsTitle),
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
              title: Text(AppLocalizations.of(context)!.followEventConfigTitle),
              subtitle:
                  Text(AppLocalizations.of(context)!.customizeYourFollowEvent),
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
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchSubscriptionGiftEventWidget(
                        TwitchSubscriptionGiftEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  tier: '2000',
                  gifterUserName: 'muxfd',
                  total: 10,
                  cumulativeTotal: 20,
                )))),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: StyleModelTheme(
                    child: TwitchSubscriptionMessageEventWidget(
                        TwitchSubscriptionMessageEventModel(
                  messageId: '',
                  timestamp: DateTime.now(),
                  subscriberUserName: 'muxfd',
                  tier: '3000',
                  cumulativeMonths: 10,
                  durationMonths: 10,
                  streakMonths: 10,
                  emotes: [],
                  text: 'Thanks for the stream!',
                )))),
            EventConfigListTile(
              title:
                  Text(AppLocalizations.of(context)!.subscribeEventConfigTitle),
              subtitle: Text(
                  AppLocalizations.of(context)!.customizeYourSubscriptionEvent),
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
              title: Text(AppLocalizations.of(context)!.cheerEventConfigTitle),
              subtitle:
                  Text(AppLocalizations.of(context)!.customizeYourCheerEvent),
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
              title: Text(AppLocalizations.of(context)!.raidEventConfigTitle),
              subtitle:
                  Text(AppLocalizations.of(context)!.customizeYourRaidEvent),
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
              title: Text(AppLocalizations.of(context)!.hostEventConfigTitle),
              subtitle:
                  Text(AppLocalizations.of(context)!.customizeYourHostEvent),
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
              title:
                  Text(AppLocalizations.of(context)!.hypetrainEventConfigTitle),
              subtitle: Text(
                  AppLocalizations.of(context)!.customizeYourHypetrainEvent),
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
              title: Text(AppLocalizations.of(context)!.pollEventConfigTitle),
              subtitle:
                  Text(AppLocalizations.of(context)!.customizeYourPollEvent),
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
              title: Text(
                  AppLocalizations.of(context)!.predictionEventConfigTitle),
              subtitle: Text(
                  AppLocalizations.of(context)!.customizeYourPredictionEvent),
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
              title: Text(AppLocalizations.of(context)!
                  .channelPointRedemptionEventConfigTitle),
              subtitle: Text(AppLocalizations.of(context)!
                  .customizeYourChannelPointRedemptionEvent),
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
              title: Text(
                  AppLocalizations.of(context)!.outgoingRaidEventConfigTitle),
              subtitle: Text(
                  AppLocalizations.of(context)!.customizeYourOutgoingRaidEvent),
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
    super.key,
    required this.title,
    required this.subtitle,
    required this.routeName,
    required this.child,
  });

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
