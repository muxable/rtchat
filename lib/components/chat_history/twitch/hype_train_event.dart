import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:styled_text/styled_text.dart';

class TwitchHypeTrainEventWidget extends StatelessWidget {
  final TwitchHypeTrainEventModel model;

  const TwitchHypeTrainEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.train,
      child: Builder(builder: (context) {
        if (model.hasEnded) {
          return StyledText(
            text:
                'Hype Train level <b>${model.level}</b> ${model.isSuccessful ? 'succeeded! ' : 'was not successful. '}',
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          );
        } else {
          return StyledText(
            text: 'Hype Train level <b>${model.level}</b> in progress! '
                '${(model.progress * 100) ~/ model.goal}% completed!',
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          );
        }
      }),
    );
  }
}
