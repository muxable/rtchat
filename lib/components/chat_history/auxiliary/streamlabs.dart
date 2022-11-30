import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';

class StreamlabsDonationEventWidget extends StatelessWidget {
  final StreamlabsDonationEventModel model;

  const StreamlabsDonationEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boldStyle = Theme.of(context).textTheme.titleSmall;
    final message = model.message;
    return DecoratedEventWidget.avatar(
      avatar: const AssetImage("assets/streamlabs.png"),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: model.name, style: boldStyle),
              const TextSpan(text: " tipped "),
              TextSpan(text: model.formattedAmount, style: boldStyle),
              const TextSpan(text: " on Streamlabs."),
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
