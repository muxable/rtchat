import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';

String getCorrespondingImageUrl(int bits) {
  if (bits <= 1) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/10.gif';
  } else if (bits > 1 && bits < 1000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/100.gif';
  } else if (bits >= 1000 && bits < 5000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/1000.gif';
  } else if (bits >= 5000 && bits < 10000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/5000.gif';
  } else if (bits >= 10000 && bits < 100000) {
    return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/10000.gif';
  }
  return 'https://cdn.twitchalerts.com/twitch-bits/images/hd/10.gif';
}

class TwitchCheerEventWidget extends StatelessWidget {
  final TwitchCheerEventModel model;

  const TwitchCheerEventWidget(this.model, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var name = model.isAnonymous ? 'Anonymous' : model.giverName;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(styleModel.fontSize),
              child: Image.network(getCorrespondingImageUrl(model.bits),
                  height: styleModel.fontSize * 1.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: name, style: boldStyle),
                    TextSpan(text: " gifted you", style: baseStyle),
                    TextSpan(text: " ${(model.bits)}", style: boldStyle),
                    TextSpan(text: " bits.", style: baseStyle),
                    TextSpan(text: " ${model.cheerMessage}", style: baseStyle)
                  ],
                ),
              ),
            )
          ]),
        ),
      );
    });
  }
}
