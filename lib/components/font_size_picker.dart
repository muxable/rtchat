import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class FontSizePickerWidget extends StatelessWidget {
  const FontSizePickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, model, child) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TwitchMessageWidget(TwitchMessageModel(
                        messageId: "placeholder",
                        author: const TwitchUserModel(login: 'muxfd'),
                        tags: {
                          "message-type": "chat",
                          "color": "#800000",
                          "badges-raw": "premium/1",
                          "emotes-raw": "25:36-40",
                          "room-id": "158394109",
                        },
                        timestamp: DateTime.now(),
                        message: "have you followed @muxfd on twitch? Kappa",
                        deleted: false,
                        channelId: 'placeholder')),
                  ),
                ),
                Text("Font size",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                    )),
                Slider.adaptive(
                  value: model.fontSize,
                  min: 12,
                  max: 36,
                  divisions: 6,
                  label: "${model.fontSize}px",
                  onChanged: (value) {
                    model.fontSize = value;
                  },
                ),
                Text("Username contrast boost",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                    )),
                Slider.adaptive(
                  value: model.lightnessBoost,
                  min: 0.179,
                  max: 1.0,
                  label: "${model.lightnessBoost}",
                  onChanged: (value) {
                    model.lightnessBoost = value;
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
            subtitle: model.isDeletedMessagesVisible
                ? const Text("Deleted messages will be greyed out")
                : const Text("Deleted messages will be removed"),
            value: model.isDeletedMessagesVisible,
            onChanged: (value) {
              model.isDeletedMessagesVisible = value;
            },
          ),
        ],
      );
    });
  }
}
