import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/models/messages/message.dart';

final player = AudioCache();

class SeparatorWidget extends StatefulWidget {
  final SeparatorModel model;

  const SeparatorWidget(this.model, {super.key});

  @override
  State<SeparatorWidget> createState() => _SeparatorWidgetState();
}

class _SeparatorWidgetState extends State<SeparatorWidget> {
  final format = DateFormat();

  @override
  void initState() {
    super.initState();
    // play if the timestamp is within 5s of now.
    // this prevents the sound from playing when the app is first loaded.
    // or the widget is rebuilt.
    final now = DateTime.now();
    final delta = now.difference(widget.model.timestamp);
    if (delta.inSeconds.abs() < 5) {
      player.play('message-sound.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          format.format(widget.model.timestamp),
          style: Theme.of(context).textTheme.caption,
        ),
      ),
    );
  }
}
