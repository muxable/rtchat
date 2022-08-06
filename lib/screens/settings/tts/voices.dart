import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/tts.dart';

class VoicesScreen extends StatelessWidget {
  const VoicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioPlayer = AudioPlayer();
    return Scaffold(
      appBar: AppBar(title: const Text('Voices')),
      body: Consumer<TtsModel>(
        builder: (context, model, child) {
          return ListView.builder(
            itemBuilder: (BuildContext context, int index) => ListTile(
              title: Text(model.voices[index]),
              trailing: IconButton(
                onPressed: () async {
                  final response = await FirebaseFunctions.instance
                      .httpsCallable("synthesize")({
                    "voice": model.voices[index],
                    "language": model.language.languageCode,
                    "text": "kevin calmly and collectively consumes cheesecake",
                  });
                  final bytes = const Base64Decoder().convert(response.data);
                  audioPlayer.playBytes(bytes);
                },
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Play sample',
              ),
              onTap: () {
                model.voice = model.voices[index];
                Navigator.pop(context);
              },
            ),
            itemCount: model.voices.length,
          );
        },
      ),
    );
  }
}
