import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';

import 'messages/twitch_chat_message.dart';

class FontSizePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, model, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Font size", style: Theme.of(context).textTheme.subtitle1),
          Container(
              height: 120,
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: TwitchChatMessage(
                      author: 'muxfd',
                      color: '#800000',
                      emotes: "25:35-39",
                      message: "have you followed muxfd on twitch? Kappa"))),
          Slider(
            value: model.fontSize,
            min: 12,
            max: 24,
            divisions: 6,
            label: "${model.fontSize}px",
            onChanged: (value) {
              model.setFontSize(value);
            },
          )
        ],
      );
    });
  }
}
