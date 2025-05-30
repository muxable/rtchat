import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:styled_text/styled_text.dart';

import './l10n/app_localizations.dart';

Uri getCorrespondingImageUrl(int bits) {
  final key = [100000, 10000, 5000, 1000, 100]
      .firstWhere((k) => k <= bits, orElse: () => 10);
  return Uri.parse(
      'https://cdn.twitchalerts.com/twitch-bits/images/hd/$key.gif');
}

class TwitchCheerEventWidget extends StatelessWidget {
  final TwitchCheerEventModel model;

  const TwitchCheerEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final name = model.isAnonymous
        ? AppLocalizations.of(context)!.anonymous
        : model.giverName ?? AppLocalizations.of(context)!.anonymous;
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(getCorrespondingImageUrl(model.bits)),
      child: StyledText(
        text: AppLocalizations.of(context)!
            .cheerEventMessage(name, model.bits, model.cheerMessage),
        tags: {
          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
        },
      ),
    );
  }
}
