import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

String getCorrespondingImageUrl(int bits) {
  final key = [100000, 10000, 5000, 1000, 100]
      .firstWhere((k) => k <= bits, orElse: () => 10);
  return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/$key.gif';
}

class TwitchCheerEventWidget extends StatelessWidget {
  final TwitchCheerEventModel model;

  const TwitchCheerEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = model.isAnonymous ? 'Anonymous' : model.giverName;
    final boldStyle = Theme.of(context).textTheme.subtitle2;
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
              child: Image.network(getCorrespondingImageUrl(model.bits),
                  height: styleModel.fontSize * 1.5),
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: name, style: boldStyle),
                  const TextSpan(text: " gifted you"),
                  TextSpan(text: " ${(model.bits)}", style: boldStyle),
                  const TextSpan(text: " bits."),
                  TextSpan(text: " ${model.cheerMessage}")
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}
