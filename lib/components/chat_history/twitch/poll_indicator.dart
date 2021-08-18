import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

class PollChoiceWidget extends StatelessWidget {
  final PollChoiceModel data;
  final bool isCompleted;
  final int maxVotes;
  final int totalVotes;
  const PollChoiceWidget(
      {Key? key,
      required this.data,
      required this.isCompleted,
      required this.maxVotes,
      required this.totalVotes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = data.votes / max(1, totalVotes);

    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);
      // winner poll gets a trophy icon
      return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(alignment: AlignmentDirectional.center, children: [
            SizedBox(
              height: 37,
              child: LinearProgressIndicator(
                value: percentage,
              ),
            ),
            if (isCompleted && data.votes >= maxVotes) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Align(
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 32,
                  ),
                  alignment: Alignment.centerLeft,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Align(
                  child: Text(
                    data.title,
                    style: baseStyle,
                  ),
                  alignment: Alignment.centerLeft,
                ),
              )
            ],
            if (!isCompleted || data.votes < maxVotes) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Align(
                  child: Text(
                    data.title,
                    style: baseStyle,
                  ),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Align(
                  child: Text("${(percentage * 100).floor()}% (${data.votes})",
                      style: baseStyle),
                  alignment: Alignment.centerRight),
            ),
          ]));
    });
  }
}
