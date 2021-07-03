import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';

class TtsOptionsWidget extends StatelessWidget {
  const TtsOptionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHistoryModel>(builder: (context, model, child) {
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
                  value: model.ttsSpeed,
                  min: 0.1,
                  max: 2,
                  label: "speed: ${model.ttsSpeed}",
                  onChanged: (value) {
                    model.ttsSpeed = value;
                  },
                ),
                Text("Text to Speech Pitch",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.bold,
                    )),
                Slider.adaptive(
                  value: model.ttsPitch,
                  min: 0.1,
                  max: 3,
                  label: "${model.ttsPitch}",
                  onChanged: (value) {
                    model.ttsPitch = value;
                  },
                ),
                Center(
                  child: ElevatedButton(
                    child: const Text("Play sample message"),
                    onPressed: () {
                      model.ttsModel.speak('muxfd',
                          'muxfd said have you followed muxfd on twitch?',
                          force: true);
                    },
                  ),
                )
              ],
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text('Mute text to speech for bots'),
            value: model.ttsIsBotMuted,
            onChanged: (value) {
              model.ttsIsBotMuted = value;
            },
          ),
        ],
      );
    });
  }
}
