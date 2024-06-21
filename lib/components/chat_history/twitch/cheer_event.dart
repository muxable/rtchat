import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:styled_text/styled_text.dart';

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
    final loc = AppLocalizations.of(context)!;
    final name = model.isAnonymous ? loc.anonymous : model.giverName;
    return DecoratedEventWidget.avatar(
      avatar: ResilientNetworkImage(getCorrespondingImageUrl(model.bits)),
      child: StyledText(
        text: loc.cheerEventMessage(name, model.bits, model.cheerMessage),
        tags: {
          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
        },
      ),
    );
  }
}
