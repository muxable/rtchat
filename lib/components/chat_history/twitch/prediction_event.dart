import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';

class TwitchPredictionEventWidget extends StatelessWidget {
  final TwitchPredictionEventModel model;

  const TwitchPredictionEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return model.status != "cancelled"
        ? DecoratedEventWidget(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(model.title,
                      style: Theme.of(context).textTheme.subtitle2)),
              ...model.outcomes.map((outcome) {
                final isWinner = model.status == "resolved" &&
                    model.winningOutcomeId == outcome.id;
                return _TwitchOutcomeWidget(
                    outcome: outcome,
                    isWinner: isWinner,
                    totalPoints: model.totalPoints);
              }).toList(),
            ],
          ))
        : Container();
  }
}

class _TwitchOutcomeWidget extends StatelessWidget {
  const _TwitchOutcomeWidget(
      {Key? key,
      required this.outcome,
      required this.isWinner,
      required this.totalPoints})
      : super(key: key);
  final TwitchPredictionOutcomeModel outcome;
  final bool isWinner;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final outcomePercentage =
        "${((outcome.points / max(1, totalPoints)) * 100).floor()}%";
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(alignment: AlignmentDirectional.center, children: [
        SizedBox(
          height: 37,
          child: LinearProgressIndicator(
            value: outcome.points / max(1, totalPoints),
            valueColor: AlwaysStoppedAnimation<Color>(outcome.widgetColor),
            backgroundColor: outcome.widgetColor.shade200,
          ),
        ),
        ...(isWinner
            ? buildWinnerIndicators(outcomePercentage)
            : buildRegularIndicators(outcomePercentage))
      ]),
    );
  }

  List<Widget> buildRegularIndicators(String outcomePercentage) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          child: Text(outcome.title),
          alignment: Alignment.centerLeft,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
            child: Text(outcomePercentage), alignment: Alignment.centerRight),
      )
    ];
  }

  List<Widget> buildWinnerIndicators(String outcomePercentage) {
    return [
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
            outcome.title,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
            child: Text(outcomePercentage), alignment: Alignment.centerRight),
      )
    ];
  }
}
