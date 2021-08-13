import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';
import 'dart:math' as math;

List<Widget> getPollsWidget(List<dynamic> choices, List<Widget> children,
    bool isCompleted, TextStyle baseStyle) {
  num totalVotes = 0;
  num totalChannelPointsVotes = 0;
  num totalBitVotes = 0;
  num maxVotes = 0;

  for (final entry in choices) {
    final votes = entry['votes'] ?? 0;
    final int bitVotes = entry['bit_votes'] ?? 0;
    final int channelPointVotes = entry['channel_point_votes'] ?? 0;
    totalVotes += votes;
    totalChannelPointsVotes += channelPointVotes;
    totalBitVotes += bitVotes;
    maxVotes = math.max(maxVotes, votes);
  }

  for (final entry in choices) {
    final String choiceName = entry['title'];
    final votes = entry['votes'] ?? 0;

    // avoid division by zero
    double percentage = 0;
    if (totalVotes > 0) {
      percentage = votes / totalVotes;
    }
    if (isCompleted && maxVotes == votes) {
      children.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Stack(alignment: AlignmentDirectional.center, children: [
            SizedBox(
              height: 37,
              child: LinearProgressIndicator(
                value: percentage,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: Align(
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 32,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 0, 0),
              child: Align(
                child: Text(
                  choiceName,
                  style: baseStyle,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
              child: Align(
                  child:
                      Text("${percentage * 100}% ($votes)", style: baseStyle),
                  alignment: Alignment.centerRight),
            ),
          ])));
    } else {
      children.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Stack(alignment: AlignmentDirectional.center, children: [
            SizedBox(
              height: 37,
              child: LinearProgressIndicator(
                value: percentage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
              child: Align(
                child: Text(
                  choiceName,
                  style: baseStyle,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
              child: Align(
                  child:
                      Text("${percentage * 100}% ($votes)", style: baseStyle),
                  alignment: Alignment.centerRight),
            ),
          ])));
    }
  }

  children.add(Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text("channel point votes: $totalChannelPointsVotes", style: baseStyle),
      Text("  bit votes: $totalBitVotes", style: baseStyle),
    ],
  ));

  return children;
}

class TwitchPollEventWidget extends StatelessWidget {
  final TwitchPollEventModel model;

  const TwitchPollEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      var boldStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize, fontWeight: FontWeight.w500);
      var baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);

      children.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Text(model.pollTitle, style: boldStyle)));
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
                  children: getPollsWidget(
                      model.choices, children, model.isCompleted, baseStyle)),
            )
          ]),
        ),
      );
    });
  }
}
