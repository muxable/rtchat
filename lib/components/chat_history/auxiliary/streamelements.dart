import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';

class StreamElementsTipEventWidget extends StatelessWidget {
  final StreamElementsTipEventModel model;

  const StreamElementsTipEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final boldStyle = Theme.of(context).textTheme.titleSmall;
    final message = model.message;
    return DecoratedEventWidget.avatar(
      avatar: const AssetImage("assets/streamelements.png"),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: model.name, style: boldStyle),
                  const TextSpan(text: " tipped "),
                  TextSpan(text: model.formattedAmount, style: boldStyle),
                  const TextSpan(text: " on StreamElements."),
                ],
              ),
            ),
            if (message != null && message.isNotEmpty)
              Text.rich(TextSpan(text: message),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
          ]),
    );
  }
}
