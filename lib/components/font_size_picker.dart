import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/messages/twitch_message.dart';
import 'package:rtchat/models/layout.dart';

class FontSizePickerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, model, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: TwitchMessageWidget(
                  author: 'muxfd',
                  type: "chat",
                  color: '#800000',
                  emotes: "25:35-39",
                  message: "have you followed muxfd on twitch? Kappa"),
            ),
          ),
          Text("Font size",
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold,
              )),
          Slider(
            value: model.fontSize,
            min: 12,
            max: 36,
            divisions: 6,
            label: "${model.fontSize}px",
            onChanged: (value) {
              model.fontSize = value;
            },
          ),
          Text("Lightness boost",
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold,
              )),
          Slider(
            value: model.lightnessBoost,
            min: 0.179,
            max: 1.0,
            label: "${model.lightnessBoost}",
            onChanged: (value) {
              model.lightnessBoost = value;
            },
          )
        ],
      );
    });
  }
}
