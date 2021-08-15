import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

class TwitchRaidEventWidget extends StatelessWidget {
  final TwitchRaidEventModel model;

  final NumberFormat _formatter = NumberFormat.decimalPattern();

  TwitchRaidEventWidget(this.model, {Key? key}) : super(key: key);

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
          Consumer<StyleModel>(builder: (context, styleModel, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(styleModel.fontSize),
              child: Image(
                  image: NetworkImageWithRetry(model.profilePictureUrl),
                  height: styleModel.fontSize * 1.5),
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: model.from.displayName,
                      style: Theme.of(context).textTheme.subtitle2),
                  const TextSpan(text: " is raiding with a party of "),
                  TextSpan(
                      text: _formatter.format(model.viewers),
                      style: Theme.of(context).textTheme.subtitle2),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}
