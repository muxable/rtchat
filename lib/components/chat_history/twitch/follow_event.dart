import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

class TwitchFollowEventWidget extends StatelessWidget {
  final TwitchFollowEventModel model;

  const TwitchFollowEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 4,
            color: Theme.of(context).accentColor,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 4, 16, 4),
        child: Row(children: [
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: model.followerName,
                      style: Theme.of(context).textTheme.subtitle2),
                  const TextSpan(text: " is following you."),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}
