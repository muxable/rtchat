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
          padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
          child: Row(children: [
            Icon(Icons.train, size: styleModel.fontSize * 1.5),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: buildMessage(baseStyle, boldStyle),
                ),
              ),
            )
          ]),
        ),
      );
    });
  }

  List<InlineSpan> buildMessage(TextStyle baseStyle, TextStyle boldStyle) {
    return model.hasEnded
        ? [
            TextSpan(text: "Hype Train level ", style: baseStyle),
            TextSpan(text: model.level.toString(), style: boldStyle),
            model.isSuccessful
                ? TextSpan(text: " succeeded! ", style: baseStyle)
                : TextSpan(text: " was not successful. ", style: baseStyle),
          ]
        : [
            TextSpan(text: "Hype Train level ", style: baseStyle),
            TextSpan(text: model.level.toString(), style: boldStyle),
            TextSpan(text: " in progress! ", style: baseStyle),
            TextSpan(
                text: "${(model.progress * 100) ~/ model.goal}% completed!",
                style: baseStyle),
          ];
  }
}
