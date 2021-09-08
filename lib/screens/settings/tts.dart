import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/tts.dart';

class TextToSpeechScreen extends StatelessWidget {
  const TextToSpeechScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text to speech")),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Text to Speech Rate",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.speed,
                    min: 0.0,
                    max: 1.0,
                    label: "speed: ${model.speed}",
                    onChanged: (value) {
                      model.speed = value;
                    },
                  ),
                  Text("Text to Speech Pitch",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.pitch,
                    min: 0.1,
                    max: 2,
                    label: "${model.pitch}",
                    onChanged: (value) {
                      model.pitch = value;
                    },
                  ),
                  Center(
                    child: ElevatedButton(
                      child: const Text("Play sample message"),
                      onPressed: () {
                        model.force(
                            'muxfd said have you followed muxfd on twitch?');
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
      }),
    );
  }
}
