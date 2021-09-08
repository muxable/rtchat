import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/cheer_event.dart';
import 'package:rtchat/components/chat_history/twitch/follow_event.dart';
import 'package:rtchat/components/chat_history/twitch/hype_train_event.dart';
import 'package:rtchat/components/chat_history/twitch/poll_event.dart';
import 'package:rtchat/components/chat_history/twitch/prediction_event.dart';
import 'package:rtchat/components/chat_history/twitch/raid_event.dart';
import 'package:rtchat/components/chat_history/twitch/subscription_event.dart';
import 'package:rtchat/components/chat_history/twitch/channel_point_event.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Configuration Selection"),
      ),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        final dateTime = DateTime.now();
        return ListView(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: StyleModelTheme(
                  child: TwitchFollowEventWidget(TwitchFollowEventModel(
                follower: const TwitchUserModel(
                    userId: '158394109', login: 'muxfd', displayName: 'muxfd'),
                messageId: '',
                timestamp: DateTime.now(),
              )))),
          ListTile(
            title: const Text('Follow event config'),
            subtitle: const Text("Customize your follow event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/follow");
            },
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
          ListTile(
            title: const Text('Subscribe event config'),
            subtitle: const Text("Customize your subscription event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/subscription");
            },
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
          ListTile(
            title: const Text('Cheer event config'),
            subtitle: const Text("Customize your cheer event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/cheer");
            },
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: StyleModelTheme(
                  child: TwitchRaidEventWidget(TwitchRaidEventModel(
                messageId: '',
                timestamp: DateTime.now(),
                from: const TwitchUserModel(
                    userId: '158394109', login: 'muxfd', displayName: 'muxfd'),
                viewers: 4,
              )))),
          ListTile(
            title: const Text('Raid event config'),
            subtitle: const Text("Customize your raid event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/raid");
            },
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
          ListTile(
            title: const Text('Hypetrain event config'),
            subtitle: const Text("Customize your hypetrain event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/hypetrain");
            },
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
          ListTile(
            title: const Text('Poll event config'),
            subtitle: const Text("Customize your poll event"),
            onTap: () {
              Navigator.pushNamed(context, "/settings/events/poll");
            },
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: StyleModelTheme(
                  child: TwitchPredictionEventWidget(TwitchPredictionEventModel(
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
          ListTile(
            title: const Text('Prediction event config'),
            subtitle: const Text('Customize your prediction event'),
            onTap: () {
              Navigator.pushNamed(context, '/settings/events/prediction');
            },
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
          ListTile(
              title: const Text('Channel point redemption event config'),
              subtitle:
                  const Text("Customize your channel point redemption event"),
              onTap: () {
                Navigator.pushNamed(context, "/settings/events/channel-point");
              }),
        ]);
      }),
    );
  }
}
