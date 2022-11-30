import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';

class SeparatorWidget extends StatelessWidget {
  final DateTime timestamp;
  final Channel channel;
  final format = DateFormat("MMM d, h:mm aa");

  static String formatDuration(Duration d) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('${hours}h');
    }
    if (tokens.isNotEmpty || minutes != 0) {
      tokens.add('${minutes}m');
    }
    tokens.add('${seconds}s');

    return tokens.join('');
  }

  SeparatorWidget(this.channel, this.timestamp, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: StreamBuilder<DateTime?>(
        stream: MessagesAdapter.instance
            .forChannelUptime(channel, timestamp: timestamp),
        builder: (context, snapshot) {
          final uptime = snapshot.data;
          if (uptime == null) {
            return Text(
              DateFormat().format(timestamp),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          final delta = timestamp.difference(uptime);
          return Text(
            "${format.format(timestamp)} [${formatDuration(delta)}]",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          );
        },
      ),
    );
  }
}
