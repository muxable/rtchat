import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
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
    isAction: false,
    isFirstTimeChatter: false,
    announcement: null,
  ),
  thirdPartyEmotes: [],
  timestamp: DateTime.now(),
  message: "have you followed @muxfd on twitch? Kappa",
  deleted: false,
  channelId: 'placeholder',
);
final message2 = TwitchMessageModel(
  messageId: "placeholder2",
  author: const TwitchUserModel(userId: 'muxfd', login: 'muxfd'),
  tags: {"color": "#DAA520", "badges-raw": "moderator/1"},
  annotations: const TwitchMessageAnnotationsModel(
    isAction: true,
    isFirstTimeChatter: false,
    announcement: null,
  ),
  thirdPartyEmotes: [],
  timestamp: DateTime.now(),
  message: "likes cows and stuff",
  deleted: true,
  channelId: 'placeholder',
);
final message3 = TwitchMessageModel(
  messageId: "placeholder3",
  author: const TwitchUserModel(
    userId: 'muxfd',
    login: 'muxfd',
    displayName: 'マックス',
  ),
  tags: {"color": "#00FF7F", "badges-raw": "broadcaster/1,moderator/1"},
  annotations: const TwitchMessageAnnotationsModel(
    isAction: false,
    isFirstTimeChatter: false,
    announcement: null,
  ),
  thirdPartyEmotes: [
    Emote(
      provider: Providers.twitch,
      category: null,
      id: 'catJAM',
      code: 'catJAM',
      imageUrl: 'https://cdn.betterttv.net/emote/5f1abd75fe85fb4472d132b4/1x',
    ),
  ],
  timestamp: DateTime.now(),
  message: "catJAM catJAM catJAM catJAM catJAM catJAM",
  deleted: false,
  channelId: 'placeholder',
);

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.chatHistory)),
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.fontSize,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    Text(
                      AppLocalizations.of(context)!.usernameContrastBoost,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                title: Text(AppLocalizations.of(context)!.twitchBadgeSettings),
                subtitle: Text(
                  AppLocalizations.of(context)!.twitchBadgeSettingsSubtitle,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, "/settings/badges");
                },
              ),
              SwitchListTile.adaptive(
                title: Text(AppLocalizations.of(context)!.showDeletedMessages),
                subtitle:
                    styleModel.isDeletedMessagesVisible
                        ? Text(
                          AppLocalizations.of(
                            context,
                          )!.deletedMessagesGreyedOut,
                        )
                        : Text(
                          AppLocalizations.of(context)!.deletedMessagesRemoved,
                        ),
                value: styleModel.isDeletedMessagesVisible,
                onChanged: (value) {
                  styleModel.isDeletedMessagesVisible = value;
                },
              ),
              SwitchListTile.adaptive(
                title: Text(AppLocalizations.of(context)!.showLoginNames),
                subtitle:
                    styleModel.isLoginShown
                        ? Text(AppLocalizations.of(context)!.loginNamesShown)
                        : Text(AppLocalizations.of(context)!.loginNamesHidden),
                value: styleModel.isLoginShown,
                onChanged: (value) {
                  styleModel.isLoginShown = value;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.compactMessages,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RadioGroup<CompactMessages>(
                groupValue: styleModel.compactMessages,
                onChanged: (value) {
                  if (value != null) {
                    styleModel.compactMessages = value;
                  }
                },
                child: Column(
                  children: [
                    RadioListTile(
                      title: Text(
                        AppLocalizations.of(context)!.dontCompactMessages,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        )!.dontCompactMessagesSubtitle,
                      ),
                      value: CompactMessages.none,
                    ),
                    RadioListTile(
                      title: Text(
                        AppLocalizations.of(context)!.compactIndividualMessages,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        )!.compactIndividualMessagesSubtitle,
                      ),
                      value: CompactMessages.withinMessage,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.announcementPinDuration,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider.adaptive(
                      value:
                          messagesModel.announcementPinDuration.inSeconds
                              .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label: AppLocalizations.of(context)!.durationSeconds(
                        messagesModel.announcementPinDuration.inSeconds,
                      ),
                      onChanged: (value) {
                        messagesModel.announcementPinDuration = Duration(
                          seconds: value.toInt(),
                        );
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
                    Text(
                      AppLocalizations.of(context)!.idleMessageAlertDuration,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.idleMessageAlertDurationSubtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              RadioGroup<Duration>(
                groupValue: messagesModel.pingMinGapDuration,
                onChanged: (value) {
                  if (value != null) {
                    messagesModel.pingMinGapDuration = value;
                  }
                },
                child: Column(
                  children: [
                    for (final (label, duration) in [
                      (
                        AppLocalizations.of(context)!.disabled,
                        const Duration(days: 10000),
                      ),
                      (
                        AppLocalizations.of(context)!.durationSeconds(30),
                        const Duration(seconds: 30),
                      ),
                      (
                        AppLocalizations.of(context)!.durationOneMinute,
                        const Duration(minutes: 1),
                      ),
                      (
                        AppLocalizations.of(context)!.durationMinutes(5),
                        const Duration(minutes: 5),
                      ),
                      (
                        AppLocalizations.of(context)!.durationTenMinutes,
                        const Duration(minutes: 10),
                      ),
                    ])
                      RadioListTile(title: Text(label), value: duration),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
