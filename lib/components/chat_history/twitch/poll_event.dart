import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/poll_indicator.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

List<Widget> getPollsWidget(TwitchPollEventModel model) {
  var choices = model.choices;
  List<Widget> children = [];
  for (final poll in choices) {
    children.add(PollChoiceWidget(
        data: poll,
        isCompleted: model.isCompleted,
        maxVotes: model.maxVotes,
        totalVotes: model.totalVotes));
  }
  return children;
}

class TwitchPollEventWidget extends StatelessWidget {
  final TwitchPollEventModel model;

  const TwitchPollEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var boldStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);

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
          padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
          child: Row(children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(model.pollTitle, style: boldStyle)),
                    // polls
                    ...getPollsWidget(model),
                    // some breakdowns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            "channel point votes: ${model.totalChannelPointsVotes}",
                            style: baseStyle),
                        Text("  bit votes: ${model.totalBitVotes}",
                            style: baseStyle),
                      ],
                    )
                  ]),
            )
          ]),
        ),
      );
    });
  }
}
