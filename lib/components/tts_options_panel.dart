import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/tts.dart';

class TtsOptionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHistoryModel>(builder: (context, model, child) {
      final ttsModel = model.ttsModule;
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // future stuff for tts speed and pitch adjustment
              ],
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text('Option to Mute Bot'),
            subtitle: const Text(
                'Useful when TTS is enabled and commands are excessively used'),
            value: ttsModel.isBotMuted,
            onChanged: (value) {
              ttsModel.isBotMuted = value;
            },
          ),
        ],
      );
    });
  }
}
