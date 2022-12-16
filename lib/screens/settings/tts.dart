import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/bytes_audio_source.dart';

class TextToSpeechScreen extends StatelessWidget {
  const TextToSpeechScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioPlayer = AudioPlayer();
    return Scaffold(
      appBar: AppBar(title: const Text("Text to speech")),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        return ListView(
          children: [
            if (kDebugMode)
              Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Cloud TTS'),
                    value: model.isCloudTtsEnabled,
                    onChanged: (value) {
                      model.isCloudTtsEnabled = value;
                    },
                  ),
                  if (model.isCloudTtsEnabled)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!model.isSupportedLanguage)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Languages",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        '/settings/text-to-speech/languages',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            width: 2,
                                            color:
                                                Theme.of(context).dividerColor),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          model.language.displayName(context),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text("Voices",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile.adaptive(
                          title: const Text('Per-viewer voice'),
                          subtitle:
                              const Text('Identify your viewers by voice'),
                          value: model.isRandomVoiceEnabled,
                          onChanged: (value) {
                            model.isRandomVoiceEnabled = value;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(
                                onPressed: model.isRandomVoiceEnabled
                                    ? null
                                    : () {
                                        Navigator.pushNamed(context,
                                            '/settings/text-to-speech/voices');
                                      },
                                style: OutlinedButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.titleLarge,
                                  side: BorderSide(
                                      width: 2,
                                      color: Theme.of(context).dividerColor),
                                ).copyWith(
                                  foregroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) =>
                                        states.contains(MaterialState.disabled)
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    model.isRandomVoiceEnabled
                                        ? 'Random'
                                        : model.voice,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (model.isCloudTtsEnabled) {
                    final response = await FirebaseFunctions.instance
                        .httpsCallable("synthesize")({
                      "voice": model.voice,
                      "rate": model.speed * 1.5 + 0.5,
                      "pitch": model.pitch * 4 - 2,
                      "text":
                          "kevin calmly and collectively consumes cheesecake",
                    });
                    final bytes = const Base64Decoder().convert(response.data);
                    audioPlayer.setAudioSource(BytesAudioSource(bytes));
                    audioPlayer.play();
                  } else {
                    model.say(
                        SystemMessageModel(
                          text: "muxfd said have you followed muxfd on twitch?",
                        ),
                        force: true);
                  }
                },
                child: const Text("Play sample message"),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    onChanged:
                        model.isRandomVoiceEnabled && model.isCloudTtsEnabled
                            ? null
                            : (value) {
                                model.pitch = value;
                              },
                  ),
                  if (kDebugMode && !model.isCloudTtsEnabled)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/settings/text-to-speech/cloud-tts',
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                      text: 'Unlock high-quality voices'),
                                  const WidgetSpan(child: SizedBox(width: 8)),
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.lock_open_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
