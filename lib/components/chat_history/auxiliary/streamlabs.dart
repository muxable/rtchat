import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';

class StreamlabsDonationEventWidget extends StatelessWidget {
  final StreamlabsDonationEventModel model;

  const StreamlabsDonationEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boldStyle = Theme.of(context).textTheme.subtitle2;
    return DecoratedEventWidget.avatar(
      avatar: const AssetImage("assets/streamlabs.png"),
      child: Column(children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: model.name, style: boldStyle),
              const TextSpan(text: " donated "),
              TextSpan(text: model.formattedAmount, style: boldStyle),
              const TextSpan(text: " on Streamlabs."),
            ],
          ),
        ),
        if (model.message != null)
          Text.rich(TextSpan(text: model.message),
              style: const TextStyle(fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
