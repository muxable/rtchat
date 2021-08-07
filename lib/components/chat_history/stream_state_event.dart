import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/models/messages/message.dart';

class StreamStateEventWidget extends StatelessWidget {
  final StreamStateEventModel model;

  const StreamStateEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd().format(model.timestamp);
    final time = DateFormat.jms().format(model.timestamp);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  model.isOnline
                      ? "Stream online at $date, $time"
                      : "Stream offline at $date, $time",
                  textAlign: TextAlign.center,
                )),
            color: Theme.of(context).dividerColor,
            width: double.infinity));
  }
}
