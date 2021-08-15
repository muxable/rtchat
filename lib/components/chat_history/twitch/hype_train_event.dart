import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/style.dart';

class TwitchHypeTrainEventWidget extends StatelessWidget {
  final TwitchHypeTrainEventModel model;

  const TwitchHypeTrainEventWidget(this.model, {Key? key}) : super(key: key);

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
        padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
        child: Row(children: [
          Consumer<StyleModel>(
            builder: (context, styleModel, child) =>
                Icon(Icons.train, size: styleModel.fontSize * 1.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: buildMessage(Theme.of(context).textTheme.subtitle2),
              ),
            ),
          )
        ]),
      ),
    );
  }

  List<InlineSpan> buildMessage(TextStyle? boldStyle) {
    return model.hasEnded
        ? [
            const TextSpan(text: "Hype Train level "),
            TextSpan(text: model.level.toString(), style: boldStyle),
            model.isSuccessful
                ? const TextSpan(text: " succeeded! ")
                : const TextSpan(text: " was not succesful. "),
          ]
        : [
            const TextSpan(text: "Hype Train level "),
            TextSpan(text: model.level.toString(), style: boldStyle),
            const TextSpan(text: " in progress! "),
            TextSpan(
                text: "${(model.progress * 100) ~/ model.goal}% completed!"),
          ];
  }
}
