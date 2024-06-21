import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:styled_text/styled_text.dart';

class StreamElementsTipEventWidget extends StatelessWidget {
  final StreamElementsTipEventModel model;

  const StreamElementsTipEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.avatar(
      avatar: const AssetImage("assets/streamelements.png"),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StyledText(
              text:
                  '<b>${model.name}</b> tipped <b>${model.formattedAmount}</b> on StreamElements.',
              tags: {
                'b': StyledTextTag(
                    style: Theme.of(context).textTheme.titleSmall),
              },
            ),
            if (model.message != null && model.message!.isNotEmpty)
              Text(model.message!,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
          ]),
    );
  }
}
