import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/poll_indicator.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

List<Widget> getPollsWidget(TwitchPollEventModel model, TextStyle baseStyle) {
  var choices = model.choices;
  List<Widget> children = [];
  for (final entry in choices) {
    final String id = entry['id'];
    final String choiceName = entry['title'];
    final int votes = entry['votes'] ?? 0;
    final int bitVotes = entry['bit_votes'] ?? 0;
    final int channelPointVotes = entry['channel_point_votes'] ?? 0;

    // avoid division by zero
    double percentage = 0;
    if (model.totalVotes > 0) {
      percentage = (votes / model.totalVotes);
    }

    var poll = PollChoiceData(
        id: id,
        title: choiceName,
        bitVotes: bitVotes,
        channelPointVotes: channelPointVotes,
        votes: votes,
        percentage: percentage);

    children.add(PollIndicatorWidget(
        data: poll, isCompleted: model.isCompleted, maxVotes: model.maxVotes));
  }
  return children;
}

class TwitchPollEventWidget extends StatelessWidget {
  final TwitchPollEventModel model;

  const TwitchPollEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List<Widget> children = [];
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var boldStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);

      // children.add(Padding(
      //     padding: const EdgeInsets.only(bottom: 8),
      //     child: Text(model.pollTitle, style: boldStyle)));
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
                    ...getPollsWidget(model, baseStyle),
                    // some breakdowns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("channel point votes: ${model.totalBitVotes}",
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
