import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';

class SeparatorWidget extends StatelessWidget {
  final SeparatorModel model;

  const SeparatorWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          model.timestamp.toIso8601String(),
          style: Theme.of(context).textTheme.caption,
        ),
      ),
    );
  }
}
