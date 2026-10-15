import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/voice_packs_debug.dart';

class TextToSpeechScreen extends StatelessWidget {
  const TextToSpeechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.textToSpeech)),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        return ListView(
          children: [
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  model.say(
                      AppLocalizations.of(context)!,
                      SystemMessageModel(
                        text: AppLocalizations.of(context)!.sampleMessage,
                      ),
                      force: true);
                },
                child: Text(AppLocalizations.of(context)!.playSampleMessage),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.textToSpeechRate,
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
                  Text(AppLocalizations.of(context)!.textToSpeechPitch,
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
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)!.muteBots),
              value: model.isBotMuted,
              onChanged: (value) {
                model.isBotMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)!.muteEmotes),
              value: model.isEmoteMuted,
              onChanged: (value) {
                model.isEmoteMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)!.muteViewerNames),
              value: model.isPreludeMuted,
              onChanged: (value) {
                model.isPreludeMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)!.subscribersOnly),
              value: model.isSubscribersOnly,
              onChanged: (value) {
                model.isSubscribersOnly = value;
              },
            ),
            if (kDebugMode)
              ListTile(
                title: const Text('Voice packs (debug)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const VoicePacksDebugScreen())),
              ),
          ],
        );
      }),
    );
  }
}
