import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

String getCorrespondingImageUrl(int bits) {
  if (bits < 100) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/10.gif';
  } else if (bits >= 100 && bits < 1000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/100.gif';
  } else if (bits >= 1000 && bits < 5000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/1000.gif';
  } else if (bits >= 5000 && bits < 10000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/5000.gif';
  } else if (bits >= 10000 && bits < 100000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/10000.gif';
  }
  return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/100000.gif';
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
