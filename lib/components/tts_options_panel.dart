import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/tts.dart';

class TtsOptionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHistoryModel>(builder: (context, model, child) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TTS Speed",
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
                Text("TTS Pitch",
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
                SwitchListTile.adaptive(
                  title: const Text('Option to Mute Bot'),
                  subtitle: const Text(
                      'Useful when TTS is enabled and commands are excessively used'),
                  value: model.ttsIsBotMuted,
                  onChanged: (value) {
                    model.ttsIsBotMuted = value;
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
