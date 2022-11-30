import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/chat_history/twitch/poll_indicator.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

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
    return DecoratedEventWidget(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // title
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(model.pollTitle,
                style: Theme.of(context).textTheme.titleSmall)),
        // polls
        ...getPollsWidget(model),
        // some breakdowns
        Text(
            "channel point votes: ${model.totalChannelPointsVotes}. bit votes: ${model.totalBitVotes}",
            style: Theme.of(context).textTheme.titleMedium)
      ]),
    );
  }
}
