import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rtchat/models/messages/message.dart';

class SeparatorWidget extends StatelessWidget {
  final SeparatorModel model;
  final format = DateFormat();

  SeparatorWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          format.format(model.timestamp),
          style: Theme.of(context).textTheme.caption,
        ),
      ),
    );
  }
}
