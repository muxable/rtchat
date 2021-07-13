import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/tts.dart';

class TtsOptionsWidget extends StatelessWidget {
  const TtsOptionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsModel>(builder: (context, model, child) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Text to Speech Rate",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                    )),
                Slider.adaptive(
                  value: model.speed,
                  min: 0.1,
                  max: 2,
                  label: "speed: ${model.speed}",
                  onChanged: (value) {
                    model.speed = value;
                  },
                ),
                Text("Text to Speech Pitch",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                    )),
                Slider.adaptive(
                  value: model.pitch,
                  min: 0.1,
                  max: 3,
                  label: "${model.pitch}",
                  onChanged: (value) {
                    model.pitch = value;
                  },
                ),
                Center(
                  child: ElevatedButton(
                    child: const Text("Play sample message"),
                    onPressed: () {
                      model.speak(
                          const TtsMessage(
                              author: 'muxfd',
                              coalescingHeader: "muxfd said",
                              message: 'have you followed muxfd on twitch?',
                              messageId: "test",
                              hasEmote: false,
                              emotes: null),
                          force: true);
                    },
                  ),
                )
              ],
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text('Mute text to speech for bots'),
            value: model.isBotMuted,
            onChanged: (value) {
              model.isBotMuted = value;
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Mute all emotes in text to speech'),
            value: model.isEmoteMuted,
            onChanged: (value) {
              model.isEmoteMuted = value;
            },
          ),
        ],
      );
    });
  }
}
