import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';

class TwitchShoutoutEventWidget extends StatelessWidget {
  const TwitchShoutoutEventWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedEventWidget.icon(
      icon: Icons.auto_awesome,
      child: Builder(builder: (context) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: "Shoutout was given to ",
                  style: Theme.of(context).textTheme.titleSmall),
              TextSpan(
                text: "Rippyae",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Colors.purpleAccent),
              ),
            ],
          ),
        );
      }),
    );
  }
}
