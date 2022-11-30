import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';

class TwitchHypeTrainEventWidget extends StatelessWidget {
  final TwitchHypeTrainEventModel model;

  const TwitchHypeTrainEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.train,
      child: Builder(builder: (context) {
        if (model.hasEnded) {
          return Text.rich(
            TextSpan(children: [
              const TextSpan(text: "Hype Train level "),
              TextSpan(
                  text: model.level.toString(),
                  style: Theme.of(context).textTheme.titleSmall),
              model.isSuccessful
                  ? const TextSpan(text: " succeeded! ")
                  : const TextSpan(text: " was not successful. "),
            ]),
          );
        } else {
          return Text.rich(TextSpan(
            children: [
              const TextSpan(text: "Hype Train level "),
              TextSpan(
                  text: model.level.toString(),
                  style: Theme.of(context).textTheme.titleSmall),
              const TextSpan(text: " in progress! "),
              TextSpan(
                  text: "${(model.progress * 100) ~/ model.goal}% completed!"),
            ],
          ));
        }
      }),
    );
  }
}
