import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';

final message1 = TwitchMessageModel(
    messageId: "placeholder1",
    author: const TwitchUserModel(userId: 'muxfd', login: 'muxfd'),
    tags: {
      "color": "#800000",
      "badges-raw": "premium/1",
      "emotes-raw": "25:36-40",
    },
    annotations: const TwitchMessageAnnotationsModel(
        isAction: false, isFirstTimeChatter: false, announcement: null),
    thirdPartyEmotes: [],
    timestamp: DateTime.now(),
    message: "have you followed @muxfd on twitch? Kappa",
    deleted: false,
    channelId: 'placeholder');
final message2 = TwitchMessageModel(
    messageId: "placeholder2",
    author: const TwitchUserModel(userId: 'muxfd', login: 'muxfd'),
    tags: {
      "color": "#DAA520",
      "badges-raw": "moderator/1",
    },
    annotations: const TwitchMessageAnnotationsModel(
        isAction: true, isFirstTimeChatter: false, announcement: null),
    thirdPartyEmotes: [],
    timestamp: DateTime.now(),
    message: "likes cows and stuff",
    deleted: true,
    channelId: 'placeholder');
final message3 = TwitchMessageModel(
    messageId: "placeholder3",
    author: const TwitchUserModel(userId: 'muxfd', login: 'muxfd'),
    tags: {
      "color": "#00FF7F",
      "badges-raw": "broadcaster/1,moderator/1",
    },
    annotations: const TwitchMessageAnnotationsModel(
        isAction: false, isFirstTimeChatter: false, announcement: null),
    thirdPartyEmotes: [
      Emote(
        provider: "twitch",
        category: null,
        id: 'catJAM',
        code: 'catJAM',
        imageUrl: 'https://cdn.betterttv.net/emote/5f1abd75fe85fb4472d132b4/1x',
      ),
    ],
    timestamp: DateTime.now(),
    message: "catJAM catJAM catJAM catJAM catJAM catJAM",
    deleted: false,
    channelId: 'placeholder');

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat history")),
      body: Consumer2<StyleModel, MessagesModel>(
          builder: (context, styleModel, messagesModel, child) {
        return ListView(
          children: [
            SizedBox(
              height: 180,
              child: StyleModelTheme(
                  child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                    TwitchMessageWidget(message1),
                    TwitchMessageWidget(message2),
                    TwitchMessageWidget(message3),
                  ])),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Font size",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: styleModel.fontSize,
                    min: 12,
                    max: 36,
                    divisions: 12,
                    label: "${styleModel.fontSize}px",
                    onChanged: (value) {
                      styleModel.fontSize = value;
                    },
                  ),
                  Text("Username contrast boost",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: styleModel.lightnessBoost,
                    min: 0.179,
                    max: 1.0,
                    label: "${styleModel.lightnessBoost}",
                    onChanged: (value) {
                      styleModel.lightnessBoost = value;
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Twitch badge settings'),
              subtitle: const Text("Control which badges are visible"),
              onTap: () {
                Navigator.pushNamed(context, "/settings/badges");
              },
            ),
            SwitchListTile.adaptive(
              title: const Text('Show deleted messages'),
              subtitle: styleModel.isDeletedMessagesVisible
                  ? const Text("Deleted messages will be greyed out")
                  : const Text("Deleted messages will be removed"),
              value: styleModel.isDeletedMessagesVisible,
              onChanged: (value) {
                styleModel.isDeletedMessagesVisible = value;
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Compact messages",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            RadioListTile(
              title: const Text('Don\'t compact messages'),
              subtitle: const Text("Messages are shown unchanged"),
              value: CompactMessages.none,
              groupValue: styleModel.compactMessages,
              onChanged: (CompactMessages? value) {
                if (value != null) {
                  styleModel.compactMessages = value;
                }
              },
            ),
            RadioListTile(
              title: const Text('Compact individual messages'),
              subtitle: const Text("Repetitive text in messages is shortened"),
              value: CompactMessages.withinMessage,
              groupValue: styleModel.compactMessages,
              onChanged: (CompactMessages? value) {
                if (value != null) {
                  styleModel.compactMessages = value;
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Announcement pin duration",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: messagesModel.announcementPinDuration.inSeconds
                        .toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 15,
                    label:
                        "${messagesModel.announcementPinDuration.inSeconds.toDouble()} seconds",
                    onChanged: (value) {
                      messagesModel.announcementPinDuration =
                          Duration(seconds: value.toInt());
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Idle message alert duration",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                      "If there aren't any messages for this amount of time and a new one comes in, an alert sound will play.",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )),
                ],
              ),
            ),
            RadioListTile(
              title: const Text('Disabled'),
              value: const Duration(days: 10000),
              groupValue: messagesModel.pingMinGapDuration,
              onChanged: (Duration? value) {
                if (value != null) {
                  messagesModel.pingMinGapDuration = value;
                }
              },
            ),
            RadioListTile(
              title: const Text('30 seconds'),
              value: const Duration(seconds: 30),
              groupValue: messagesModel.pingMinGapDuration,
              onChanged: (Duration? value) {
                if (value != null) {
                  messagesModel.pingMinGapDuration = value;
                }
              },
            ),
            RadioListTile(
              title: const Text('1 minute'),
              value: const Duration(minutes: 1),
              groupValue: messagesModel.pingMinGapDuration,
              onChanged: (Duration? value) {
                if (value != null) {
                  messagesModel.pingMinGapDuration = value;
                }
              },
            ),
            RadioListTile(
              title: const Text('5 minutes'),
              value: const Duration(minutes: 5),
              groupValue: messagesModel.pingMinGapDuration,
              onChanged: (Duration? value) {
                if (value != null) {
                  messagesModel.pingMinGapDuration = value;
                }
              },
            ),
            RadioListTile(
              title: const Text('10 minutes'),
              value: const Duration(minutes: 10),
              groupValue: messagesModel.pingMinGapDuration,
              onChanged: (Duration? value) {
                if (value != null) {
                  messagesModel.pingMinGapDuration = value;
                }
              },
            ),
          ],
        );
      }),
    );
  }
}
