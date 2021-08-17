import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image/network.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';

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
    return DecoratedEventWidget.avatar(
      avatar: NetworkImageWithRetry(getCorrespondingImageUrl(model.bits)),
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
    );
  }
}
