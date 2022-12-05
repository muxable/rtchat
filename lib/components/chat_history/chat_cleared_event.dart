import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/models/messages/message.dart';

class ChatClearedEventWidget extends StatelessWidget {
  final ChatClearedEventModel model;

  const ChatClearedEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd().format(model.timestamp);
    final time = DateFormat.jms().format(model.timestamp);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          color: Theme.of(context).dividerColor,
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                "Chat cleared at $date, $time",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )),
        ));
  }
}
