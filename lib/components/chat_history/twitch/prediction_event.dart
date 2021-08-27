import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/style.dart';

class TwitchPredictionEventWidget extends StatelessWidget {
  final TwitchPredictionEventModel model;

  const TwitchPredictionEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      final baseStyle = Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(fontSize: styleModel.fontSize);

      return model.status != "cancelled"
          ? DecoratedEventWidget(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(model.title,
                        style: Theme.of(context).textTheme.subtitle2)),
                ...model.outcomes
                    .map((outcome) => buildOutcomeWidget(baseStyle, outcome))
                    .toList(),
              ],
            ))
          : Container();
    });
  }

  Widget buildOutcomeWidget(
      TextStyle baseStyle, TwitchPredictionOutcomeModel outcome) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(alignment: AlignmentDirectional.center, children: [
        SizedBox(
          height: 37,
          child: LinearProgressIndicator(
            value: outcome.points / max(1, model.totalPoints),
            valueColor: AlwaysStoppedAnimation<Color>(outcome.widgetColor),
            backgroundColor: outcome.widgetColor.shade200,
          ),
        ),
        ...(model.status == "resolved" && model.winningOutcomeId == outcome.id
            ? buildWinnerTexts(baseStyle, outcome)
            : buildRegularTexts(baseStyle, outcome))
      ]),
    );
  }

  List<Widget> buildRegularTexts(
      TextStyle baseStyle, TwitchPredictionOutcomeModel outcome) {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          child: Text(
            outcome.title,
            style: baseStyle,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
            child: Text(
                "${((outcome.points / max(1, model.totalPoints)) * 100).floor()}%",
                style: baseStyle),
            alignment: Alignment.centerRight),
      )
    ];
  }

  List<Widget> buildWinnerTexts(
      TextStyle baseStyle, TwitchPredictionOutcomeModel outcome) {
    return <Widget>[
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
            style: baseStyle,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
            child: Text(
                "${((outcome.points / max(1, model.totalPoints)) * 100).floor()}%",
                style: baseStyle),
            alignment: Alignment.centerRight),
      )
    ];
  }
}
